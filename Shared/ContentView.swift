//
//  ContentView.swift
//  Shared
//
//  Created by 한상준 on 2022/05/28.
//

import SwiftUI
import Combine


struct ItemInformation: Codable, Hashable {
    var isPurchased: Bool = false
    var isBookmarked: Bool = false
    var title: String = ""
    var id: String = ""
}

struct ContentModel{
    
    func updateItem(_ item: ItemInformation){
        var items = getItem()
        
        for row in 0 ..< items.count {
            print("@@@@@ item id = \(item.id)")
            print("@@@@@ compare item id = \(items[row].id)")
            if items[row].id == item.id{
                items[row] = item
                
                print("@@@@@@ update item info \(item)")
                print("@@@@@@ update result of items[row] is \(items[row])")
                
                print("@@@@@ update item complete")
                break
            }
        }
        setItem(items)
    }
    
    func addAndGetItems(newItemTitle: String)  -> [ItemInformation] {
        addItem(title: newItemTitle)
        return getItem()
    }
    func addItem(title: String) {
        guard title.isEmpty == false else { return }
        let uuid = UUID().uuidString
        let newItem = ItemInformation(title: title, id: uuid)
        
        var origin = getItem()
        origin.append(newItem)
        setItem(origin)
    }
    
    func getItem() -> [ItemInformation] {
        if let data = UserDefaults.standard.value(forKey:"items") as? Data {
            if let items = try? PropertyListDecoder().decode(Array<ItemInformation>.self, from: data) {
                return items
            }
        }
        return []
    }
    
    func setItem(_ items : [ItemInformation]){
        UserDefaults.standard.set(try? PropertyListEncoder().encode(items), forKey:"items")
    }
}
class ContentViewModel: ObservableObject {
    // input
    @Published var inputFieldText = ""
    let addButtonTapped = PassthroughSubject<Void, Never>()
    let viewOnAppear = PassthroughSubject<Void, Never>()
    
    // output
    @Published var itemList: [ItemInformation] = []
    
    var storage = Set<AnyCancellable>()
    
    init(model:ContentModel = ContentModel()) {
        
        addButtonTapped.merge(with: viewOnAppear)
            .map { _ in  self.inputFieldText }
            .map { model.addAndGetItems(newItemTitle: $0) }
            .assign(to: &$itemList)
    }
}
struct InputFieldWithButton : View {
    @ObservedObject var viewModel: ContentViewModel
    
    @State var textFieldText : String = ""
    
    var body: some View {
        HStack {
            Spacer(minLength: 20)
            TextField("무엇을 구매하실 건가요?", text: $viewModel.inputFieldText)
            
            Button {
                viewModel.addButtonTapped.send(Void())
            } label: {
                Text("추가").foregroundColor(Color.black)
            }.buttonStyle(HeaderButtonStyle())

            Spacer(minLength: 20)

        }
    }
    
    struct HeaderButtonStyle: ButtonStyle {
        var foregroundColor: Color = .white
        var backgroundColor: Color = .gray
        var pressedColor: Color = Color.accentColor

        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .font(.subheadline)
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                .foregroundColor(foregroundColor)
                .background(configuration.isPressed ? pressedColor : backgroundColor)
                .cornerRadius(5)
        }
    }
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }
}

class ListItemViewModel: ObservableObject {
    let checkButtonTapped = PassthroughSubject<Void, Never>()
    let starButtonTapped = PassthroughSubject<Void, Never>()


    @Published var starText = "OFF"
    @Published var checkText = "OFF"
    
    var item : ItemInformation
    init(model: ContentModel = ContentModel(), item: ItemInformation) {
        self.item = item
        
        
        print("@@@@@@ item info \(item)")
        self.starText = self.item.isBookmarked ? "star.fill" : "star"
        self.checkText = self.item.isPurchased ? "checkmark.square.fill" : "checkmark.square"

        checkButtonTapped
            .map { _ -> String in
                self.item.isPurchased = !self.item.isPurchased
                model.updateItem(self.item)
                return self.item.isPurchased ? "checkmark.square.fill" : "checkmark.square"
            }
            .assign(to: &$checkText)
        
        starButtonTapped
            .map { _ -> String in
                self.item.isBookmarked = !self.item.isBookmarked
                model.updateItem(self.item)
                return self.item.isBookmarked ? "star.fill" : "star"
            }
            .assign(to: &$starText)
    }
}

struct ListItemView: View {
    @ObservedObject var viewModel: ListItemViewModel
    
    init(itemInfo: ItemInformation){
        self.viewModel = ListItemViewModel(item: itemInfo)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: { viewModel.checkButtonTapped.send(Void()) }){
                Image(systemName:viewModel.checkText)
                    .resizable()
                    .frame(width: 20, height: 20)
                    
            }.buttonStyle(PlainButtonStyle())
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            
            Text(viewModel.item.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            Button(action: { viewModel.starButtonTapped.send(Void()) }){
                Image(systemName:viewModel.starText)
                    .resizable()
                    .frame(width: 20, height: 20)
    
            }.buttonStyle(PlainButtonStyle())
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        }.frame(maxWidth: .infinity)
            .background(
                Color(.displayP3, red: 246/255, green: 246/255, blue: 246/255, opacity: 1)
                    .clipShape(RoundedRectangle(cornerRadius:10))
            )
        
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    var body: some View {
        NavigationView {
            VStack {
                
                InputFieldWithButton(viewModel: viewModel)
                
                List{
                    ForEach(viewModel.itemList, id: \.self) { item in
                        ListItemView(itemInfo: item)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                    }
                }.listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.viewOnAppear.send(Void())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
