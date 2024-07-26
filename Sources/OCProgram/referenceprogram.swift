import Foundation
import CodableCSV
import OCGUI

/// An error thrown by this program.
struct OCError : Error {
    /// The error message.
    let message: String
}


/// An item on the menu.
struct MenuItem : Codable, CustomStringConvertible {
    /// The minimum price allowed for an item.
    static let minimumPrice: Double = 0.01

    /// The name of the item.
    let name: String

    /// The price of the item in New Zealand dollars.
    let price: Double

    /// Whether the item can be part of a vegan diet.
    let vegan: Bool

    /// Create an item, with validation.
    /// 
    /// - Parameters:
    ///   - name: the name of the item.
    ///   - price: the price of the item in New Zealand dollars.
    ///   - vegan: whether the item can be part of a vegan diet.
    init(name: String, price: Double, vegan: Bool) throws {
        // Check that the name is not empty.
        if name.count > 0 {
            self.name = name
        } else {
            // If the name is empty, throw an error.
            throw OCError(message: "Menu items cannot have empty names.")
        }

        // Check that the price is not zero or negative.
        if price >= MenuItem.minimumPrice {
            self.price = price
        } else {
            // If the price is invalid, throw an error.
            throw OCError(message: "Menu items cannot have a nil or negative price.")
        }

        // Set the vegan Boolean flag.
        self.vegan = vegan
    }

    /// The item's price as a string formatted for New Zealand Dollars.
    var priceString: String {
        let numberString: String = String(format: "%.2f", self.price)
        return "$\(numberString)"
    }

    /// The item's vegan-friendliness as a string.
    var veganString: String {
        return if self.vegan { "🍃 Vegan" } else { "🚫 Non-vegan" }
    }

    // Conformance to Codable.
    enum CodingKeys : Int, CodingKey {
        case name = 0
        case price = 1
        case vegan = 2
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        return "\(self.name) \(self.veganString.first!) .......... \(self.priceString)"
    }
}


/// A menu of items for sale at the Café.
struct Menu : CustomStringConvertible {
    /// The items available.
    let items: [MenuItem]

    init(items: [MenuItem]) throws {
        // Check that there is at least one item.
        if items.count > 0 {
            self.items = items
        } else {
            // If there are no items, throw an error.
            throw OCError(message: "Menu cannot be empty.")
        }
    }

    /// Search for an item by name.
    /// 
    /// - Parameters:
    ///   - forName: the name of the item to search for.
    /// 
    /// - Returns: An item if one is found, otherwise nil.
    func item(forName name: String) -> MenuItem? {
        // Find the first matching item in the array.
        return self.items.first(where: { $0.name.lowercased() == name.lowercased() })
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create a string builder.
        var builder: String = "MENU\n"

        // Enumerate the menu to get the item indices, then add one.
        for (index, item) in self.items.enumerated() {
            builder = builder + "\(index + 1). \(item)\n"
        }

        return builder
    }
}


/// The items that the user will order.
struct Cart : CustomStringConvertible {
    /// The maximum number of items allowed in the cart.
    static let maximumItemCount: Int = 5

    /// The user's items. Items will be added to/removed from it.
    var items: [MenuItem] = []

    /// Get the crat's total price as a string formatted for NZD.
    var priceString: String {
        // Calculate the price of ALL items in the cart.
        var total: Double = 0.0
        for item in self.items {
            total = total + item.price
        }

        let numberString: String = String(format: "%.2f", total)
        return "$\(numberString)"
    }

    /// Add an item to the cart, if it's not already full.
    /// 
    /// - Parameters:
    ///   - itemNamed: the name of the item to search for and add (if possible).
    ///   - fromMenu: the menu from which to find the item.
    mutating func add(itemNamed name: String, fromMenu menu: Menu) throws {
        // Make sure the cart is not full.
        guard self.items.count != Cart.maximumItemCount else {
            // If the cart is full, throw an error.
            throw OCError(message: "Cart is full.")
        }

        // Search for the item.
        guard let item = menu.item(forName: name) else {
            // If no item could be found, throw an error.
            throw OCError(message: "No such item '\(name)' found in menu.")
        }

        // Otherwise, add the item.
        self.items.append(item)
    }

    /// Remove an item from the cart, if it exists in the cart.
    /// 
    /// - Parameters:
    ///   - name: the name of the item to search for and add (if possible).
    mutating func remove(itemNamed name: String) throws {
        // Search for the item's index.
        guard let itemIndex = self.items.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) else {
            // If no item could be found, throw an error.
            throw OCError(message: "No such item '\(name)' found in cart.")
        }

        // Remove the found item.
        self.items.remove(at: itemIndex)
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create a string builder.
        var builder: String = "CART\n"

        // Enumerate the menu to get the item indices, then add one.
        for (index, item) in self.items.enumerated() {
            builder = builder + "\(index + 1). \(item)\n"
        }

        // Add the total price.
        builder = builder + "TOTAL: \(self.priceString)\n"

        return builder
    }
}

/// A completed order from a user to the café.
struct Order : CustomStringConvertible {
    /// The items that are part of the order.
    let cart: Cart

    init(cart: Cart) throws {
        // Check that the cart has any items in it.
        if !cart.items.isEmpty {
            self.cart = cart
        } else {
            // If the cart is empty, throw an error.
            throw OCError(message: "Orders cannot be empty.")
        }
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Split the cart lines up.
        let cartLines: [String] = self.cart.description.components(separatedBy: "\n")

        // Remove the first line so that it doesn't say "CART".
        let cartString: String = cartLines[1...].joined(separator: "\n")

        return cartString
    }
}

/// A collection of orders that have been placed.
struct OrderHistory : CustomStringConvertible {
    /// The orders that have been completed by users. Orders will be added to it.
    var orders: [Order] = []

    /// Add a new order to the order history.
    mutating func add(order: Order) {
        self.orders.append(order)
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create a string builder.
        var builder: String = "ORDERS\n"

        // Loop over every order and print its items and total.
        for order in self.orders {
            builder = builder + order.description + "\n"
        }

        return builder
    }
}


/// The program, GUI-based.
class OnslowOrdersGUIProgram : OCApp {
    /// The menu from which to order.
    var menu: Menu? = nil
    
    /// The user's cart. It begins empty.
    var cart: Cart = Cart()

    /// The history of orders, so far. It begins empty.
    var orderHistory: OrderHistory = OrderHistory()

    // GUI controls.
    let menuListView = OCListView()
    let priceLabel = OCLabel(text: "")
    let veganLabel = OCLabel(text: "")
    let addToOrderButton = OCButton(text: "Add to order")
    let cartItemsVBox = OCVBox(controls: [])
    let cartPriceLabel = OCLabel(text: "")
    let placeOrderButton = OCButton(text: "Place order")

    // Track the remove buttons.
    var removeButtons: [OCButton] = []

    /// Update the labels when a new menu item is selected.
    func onMenuListViewChange(listView: any OCControlChangeable, selected: OCListItem) {
        // Get the item.
        guard let item: MenuItem = self.menu!.item(forName: selected.text) else {
            // Just don't do anything if no item can be loaded.
            return
        }

        // Otherwise, update the labels.
        self.priceLabel.text = item.priceString
        self.veganLabel.text = item.veganString
    }

    /// Recreate the items VBox when anything is added/removed.
    func recreateItemsVBox() {
        // Reset the GUI.
        self.cartItemsVBox.empty()
        self.removeButtons = []

        for item in self.cart.items {
            // The label and the remove button for the cart item.
            let label = OCLabel(text: item.name)
            let removeButton = OCButton(text: "➖")
            removeButton.onClick(self.onRemoveButtonClick)
            self.removeButtons.append(removeButton)

            // Add the cart item with the controls side by side.
            let itemHBox = OCHBox(controls: [label, removeButton])
            itemHBox.width = OCSize.percent(100)
            itemHBox.height = OCSize.pixels(50)
            self.cartItemsVBox.append(control: itemHBox)
        }

        // Add the cart total price to the GUI.
        self.cartPriceLabel.text = self.cart.priceString

        // If there are items in the cart, enable the place order button.
        self.placeOrderButton.enabled = !self.cart.items.isEmpty

        // If the cart is full, disable the add to order button.
        self.addToOrderButton.enabled = self.cart.items.count != Cart.maximumItemCount
    }

    /// Add the selected item to the order.
    func onAddToOrderButtonClick(button: any OCControlClickable) {
        // Check that a selection has been made.
        guard let selected = self.menuListView.selectedItem else {
            // If an item isn't selected, just don't do anything.
            return
        }
        let itemName: String = selected.text

        // Add the item to the cart.
        do {
            try self.cart.add(itemNamed: itemName, fromMenu: self.menu!)
            // Add the item to the GUI.
            self.recreateItemsVBox()
            OCDialog(title: "Success", message: "Added \(itemName)!", app: self).show()
        } catch {
            if let error = error as? OCError {
                OCDialog(title: "Add error", message: error.message, app: self).show()
            }
        }
    }

    /// Remove an item from the order.
    func onRemoveButtonClick(button: any OCControlClickable) {
        do {
            let button = button as! OCButton
            // Not using if-let or guard-let here because I **know** that the button exists in the list.
            // It is guaranteed by `self.recreateItemsVBox`. Therefore, I use `!` at the end of this call.
            let index = self.removeButtons.firstIndex(where: { $0.pythonObject == button.pythonObject })!
            try self.cart.remove(itemNamed: self.cart.items[index].name)

            // Remove the item from the GUI.
            self.recreateItemsVBox()
        } catch {
            if let error = error as? OCError {
                OCDialog(title: "Remove error", message: error.message, app: self).show()
            }
        }
    }

    /// Place the order, if possible.
    func onPlaceOrderButtonClick(button: any OCControlClickable) {
        do {
            // Create the order.
            let order: Order = try Order(cart: self.cart)

            // Add the order to the order history.
            self.orderHistory.add(order: order)
            let dialog = OCDialog(title: "Success", message: "", app: self)
            // Show each new line in the order's description as a new label.
            for (index, line) in order.description.components(separatedBy: "\n").enumerated() {
                try dialog.addField(key: "\(index)", field: OCLabel(text: line))
            }
            dialog.show()

            // Create a new cart.
            self.cart = Cart()
            self.recreateItemsVBox()
        } catch {
            if let error = error as? OCError {
                OCDialog(title: "Add error", message: error.message, app: self).show()
            }
        }
    }

    /// Main method.
    override open func main(app: any OCAppDelegate) -> OCControl {
        // Load the menus.
        let decoder: CSVDecoder = CSVDecoder(configuration: { $0.headerStrategy = .firstLine })

        // Read in the food menu.
        guard let foodText = try? String(contentsOfFile: "food_menu.txt"),
        let foodItems = try? decoder.decode([MenuItem].self, from: foodText) else {
            print("Cannot load food.")
            exit(0)
        }

        // Read in the drinks menu.
        guard let drinksText = try? String(contentsOfFile: "drinks_menu.txt"),
        let drinksItems = try? decoder.decode([MenuItem].self, from: drinksText) else {
            print("Cannot load drinks.")
            exit(0)
        }

        // Set the menu.
        guard let menu = try? Menu(items: foodItems + drinksItems) else {
            print("Cannot create menu.")
            exit(0)
        }
        self.menu = menu

        // Set up control widths.
        self.menuListView.width = OCSize.percent(100)
        self.cartItemsVBox.width = OCSize.percent(100)

        // Set control states.
        self.placeOrderButton.enabled = false

        // Add menu items to menu list view.
        for item in self.menu!.items {
            self.menuListView.append(item: item.name)
        }

        // Set up event methods.
        self.menuListView.onChange(self.onMenuListViewChange)
        self.addToOrderButton.onClick(self.onAddToOrderButtonClick)
        self.placeOrderButton.onClick(self.onPlaceOrderButtonClick)

        // Set up the layout.
        let menuVBox = OCVBox(controls: [self.menuListView, self.priceLabel, self.veganLabel, self.addToOrderButton])
        let cartVBox = OCVBox(controls: [self.cartItemsVBox, self.cartPriceLabel, self.placeOrderButton])
        return OCHBox(controls: [menuVBox, cartVBox])
    }
}

OnslowOrdersGUIProgram().start()