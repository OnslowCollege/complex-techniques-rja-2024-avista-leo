// Avista + Leo Inc.
//
// Founded by Avista Goswami + Leo Evans
// Founded on 23/06/2024

import Foundation
import OCGUI
import CodableCSV

/// An error thrown by this program.
struct WebError : Error {
    /// Error message for the user.
    let message: String
}

/// An item on the catalogue
struct CatalogueItem: Codable, CustomStringConvertible {
    /// minimum price allowed for an item in the catalogue
    static let minPrice: Double = 0.01

    /// item name
    let itemName: String

    /// price of the item in NZD
    let itemPrice: Double

    /// product information
    let productInfo: String

    /// Create an item with validation
    ///
    /// - Parameters:
    ///     - itemName: name of the item in the catalogue
    ///     - itemPrice: price of the item in the catalogue
    ///     - productInfo: users can view information about products in the catalogue.
    init(itemName: String, itemPrice: Double, productInfo: String) throws{
        // if statement to check that itemName is not empty
        if itemName.count > 0 {
            self.itemName = itemName
            // if itemName is empty, give the user an error message
        } else {
            throw WebError(message: "Items in the catalogue require at least one character.")
        }

        // if statement to check itemPrice is a valid # (no 0s or negatives)
        if itemPrice >= CatalogueItem.minPrice {
            self.itemPrice = itemPrice
            // if itemPrice is invalid, give the user a warning
        } else {
            throw WebError(message: "Sorry we do not give out any items for free nor do we pay customers to take our items.")
        }

        // if statement to check that productInfo is not empty
        if productInfo.count > 0 {
            self.productInfo = productInfo
            // if productInfo is empty, give the user an error message
        } else {
            throw WebError(message: "Items in the catalogue require at least one character.")
        }
    }

    // Conformance to Codable.
    enum CodingKeys : Int, CodingKey {
        case itemName = 0
        case itemPrice = 1
        case productInfo = 2
    }

    /// Catalogue Item's price as a string formatted in NZD
    var priceDescription: String {
        let numberDescription: String = String(format: "%.2f", self.itemPrice)
        return "$\(numberDescription)"
    }

    /// Product Description for the user as a string.
    var productDescription: String {
        return productInfo
    }

    /// Compatibility with CustomStringConvertible
    var itemDescription: String {
        return "\(self.itemName)..... \(self.productInfo).......... \(self.priceDescription)"
    }

    var description: String {
        return self.itemDescription
    }
}

/// A catalogue of items avalaible for sale on the website0
struct Catalogue: CustomStringConvertible {
    /// items available to purchase for the user
    let availableItems: [CatalogueItem]

    init(availableItems: [CatalogueItem]) throws {
        // Checks that there is at least one item available on the catalogue
        if availableItems.count > 0 {
            self.availableItems = availableItems
        } else {
            // If there are 0 items on the catalogue, throw an error
            throw WebError(message: "Catalogue requires at least one item for sale.")
        }
    }

    /// Search for an item by name in the catalogue.
    /// 
    /// - Parameters:
    ///   - NameToSearch: Name of Catalogue item to search for.
    /// 
    /// - Returns: availableItem (items available to purchase for the user), otherwise nil
    func FindItem(NameToSearch itemName: String) -> CatalogueItem? {
        // Find the first matching item in the array.
        return self.availableItems.first(where: { $0.itemName.lowercased() == itemName.lowercased() })
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create a string builder.
        var builder: String = "MENU\n"

        // Enumerate Catalogue to get Catalogue Item indices, then plus one.
        for (index, availableItem) in self.availableItems.enumerated() {
            builder = builder + "\(index + 1). \(availableItem)\n"
        }
        return builder
    }
}


/// items user will order from the Catalogue
struct Cart: CustomStringConvertible {
    /// our decided max limit of items user is allowed to order in one order.
    static let cartLimit: Int = 5

    /// The user's items. Items will be added to/removed from it.
    var userItems: [CatalogueItem] = []

    /// Get cart's total price as string formatted for NZD.
    var totalPriceString: String {
        // Calculate price of ALL items in cart.
        var GrandTotal: Double = 0.0
        for item in self.userItems {
            GrandTotal = GrandTotal + item.itemPrice
        }

        let TotalString: String = String(format: "%.2f", GrandTotal)
        return "$\(TotalString)"
    }

    /// User to add item to cart, as long as cart hasn't reached max limit
    /// 
    /// - Parameters:
    ///   - itemX: name of item to search for + add (if possible).
    ///   - fromCatalogue: catalogue to find item.
    mutating func addItem(itemX name: String, fromCatalogue catalogue: Catalogue) throws {
        // Check that cart has not reached max limit
        guard self.userItems.count != Cart.cartLimit else {
            // If cart has reached max limit, throw error.
            throw WebError(message: "Sorry, cart is full.")
        }

        // Search for item in catalogue
        guard let item = catalogue.FindItem(NameToSearch: name) else {
            // If no item found, throw WebError.
            throw WebError(message: "No such item '\(name)' found in catalogue.")
        }

        // Otherwise, add item to cart.
        self.userItems.append(item)
    }

    /// Remove item from cart, if it exists in cart.
    /// 
    /// - Parameters:
    ///   - RemoveItemName: name of item to search for + remove (if possible).
    mutating func removeItem(RemoveItemName name: String) throws {
        // Search for item's index.
        guard let removeitemIndex = self.userItems.firstIndex(where: { $0.itemName.lowercased() == name.lowercased() }) else {
            // If no item could be found, throw an error.
            throw WebError(message: "No such item '\(name)' found in cart.")
        }

        // Remove found item.
        self.userItems.remove(at: removeitemIndex)
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create string builder.
        var builder: String = "CART\n"

        // Enumerate menu to get item indices, then plus one.
        for (index, availableItem) in self.userItems.enumerated() {
            builder = builder + "\(index + 1). \(availableItem)\n"
        }

        // Add the total price.
        builder = builder + "TOTAL: \(self.totalPriceString)\n"
        return builder
    }
}

/// A finished order from user to website.
struct userOrder : CustomStringConvertible {
    /// The catalogue items that are part of user's order.
    let cart: Cart

    init(cart: Cart) throws {
        // Check if cart contains any catalogue items.
        if !cart.userItems.isEmpty {
            self.cart = cart
        } else {
            // If cart contains no items, throw error.
            throw WebError(message: "Sorry, your order cannot be empty.")
        }
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // To split cart lines.
        let cartLinesSplit: [String] = self.cart.description.components(separatedBy: "\n")

        // Remove first line so it doesn't say "CART".
        let cartDescription: String = cartLinesSplit[1...].joined(separator: "\n")

        return cartDescription
    }
}

/// History of orders which have been placed so far by user.
struct userOrderHistory : CustomStringConvertible {
    /// Orders which have been placed by user. Finished orders will be added to this array.
    var allOrders: [userOrder] = []

    /// Add new order to order history.
    mutating func addOrder(order: userOrder) {
        self.allOrders.append(order)
    }

    /// Conformance to CustomStringConvertible.
    var description: String {
        // Create string builder.
        var builder: String = "ORDERS\n"

        // Loop over each individual order and print its items and total price.
        for order in self.allOrders {
            builder = builder + order.description + "\n"
        }
        return builder
    }
}

/// A struct to hold customer information
struct customerInfo: Codable {
    var name: String
    var email: String
    var address: String

    init(name: String, email: String, address: String) throws {
        guard !name.isEmpty else { throw WebError(message: "Name cannot be empty.") }
        guard !email.isEmpty else { throw WebError(message: "Email cannot be empty.") }
        guard !address.isEmpty else { throw WebError(message: "Address cannot be empty.") }
        
        self.name = name
        self.email = email
        self.address = address
    }
}

/// start of GUI Program
class SalesWebsiteGUIProgram: OCApp {

    // Catalogue from where user selects items to order
    var catalogue: Catalogue? = nil

    /// User's cart. It begins empty.
    var userCart: Cart = Cart()

    /// User's collection of orders, so far. This begins empty.
    var orderHistory: userOrderHistory = userOrderHistory()

    // GUI controls for program
    let cartListView = OCListView()
    let priceTag = OCLabel(text: "")
    let addToCartButton = OCButton(text: "Add to Cart")
    let cartItemsVBox = OCVBox(controls: [])
    let cartPriceLabel = OCLabel(text: "")
    let orderButton = OCButton(text: "Confirm Order: ")
    var catalogueList: [OCImageView] = []
    let descriptionLabel = OCLabel(text: "") 
    let showOrderHistoryButton = OCButton(text: "Show Order History")
    let orderHistoryLabel = OCLabel(text: "")


    // Track remove buttons.
    var totalRemoveButtons: [OCButton] = []

    // Store customer information
    var customer: customerInfo? = nil
    

    /// Update labels when new catalogue item is selected by user.
    func onCartListViewChange(listView: any OCControlChangeable, selected: OCListItem) {
        // Get item from catalogue.
        guard let item: CatalogueItem = self.catalogue!.FindItem(NameToSearch: selected.text) else {
            // If no item can be loaded, do nothing.
            print("No item found in catalogue upon selection.")
            return
        }

        // Otherwise, update labels.
        self.priceTag.text = item.priceDescription
        self.descriptionLabel.text = item.productDescription
    }

    /// Recreate items VBox when anything is added or removed.
    func resetItemsVBox() {
        // Reset GUI.
        self.cartItemsVBox.empty()
        self.totalRemoveButtons = []

        for item in self.userCart.userItems {
            // Label and the remove button for cart item.
            let label = OCLabel(text: item.itemName)
            let buttonRemove = OCButton(text: "➖")
            buttonRemove.onClick(self.onRemoveButtonClick)
            self.totalRemoveButtons.append(buttonRemove)

            // Add cart item with controls side by side.
            let cartItemHBox = OCHBox(controls: [label, buttonRemove])
            cartItemHBox.width = OCSize.percent(100)
            cartItemHBox.height = OCSize.pixels(50)
            self.cartItemsVBox.append(control: cartItemHBox)
        }

        // Add cart's total price to GUI.
        self.cartPriceLabel.text = self.userCart.totalPriceString

        // If cart contains items, enable order button.
        self.orderButton.enabled = !self.userCart.userItems.isEmpty

        // If cart full (meaning it contains 5 items), disable add to cart button.
        self.addToCartButton.enabled = self.userCart.userItems.count != Cart.cartLimit
    }

    /// Add selected item to cart.
    func onAddToCartButtonClick(button: any OCControlClickable) {
        // Check a selection has been made by user.
        guard let selectedIndex = self.cartListView.selectedIndex else {
            // If an item hasn't been selected by user, do nothing.
            print("No item selected.")
            return
        }

        let itemName: String = self.catalogue!.availableItems[selectedIndex].itemName

        // Add item to cart.
        do {
            try self.userCart.addItem(itemX: itemName, fromCatalogue: self.catalogue!)
            // Add the item to the GUI.
            self.resetItemsVBox()
            OCDialog(title: "Success", message: "Added \(itemName)!", app: self).show()
            // If item not successfully added, throw WebError to user.
        } catch {
            print(error)
            if let error = error as? WebError {
                OCDialog(title: "Add error", message: error.message, app: self).show()
            }
        }
    }

    /// Remove an item from user's cart.
    func onRemoveButtonClick(button: any OCControlClickable) {
        do {
            let button = button as! OCButton
            let index = self.totalRemoveButtons.firstIndex(where: { $0.pythonObject == button.pythonObject })!
            try self.userCart.removeItem(RemoveItemName: self.userCart.userItems[index].itemName)

            // Remove item from GUI.
            self.resetItemsVBox()

            // Adjust cart's total price to GUI after removing item.
            self.cartPriceLabel.text = self.userCart.totalPriceString

        
        } catch {
            if let error = error as? WebError {
                OCDialog(title: "Remove error", message: error.message, app: self).show()
            }
        }
    }

    /// Method to place order.
    func onOrderButtonClick(button: any OCControlClickable) {
        // Create a dialog for collecting customer information
        let customerInfoDialog = OCDialog(title: "Customer Information", message: "Please enter your details.", app: self)
        
        // Create fields for customer information
        let nameField = OCTextField(hint: "Customer Name")
        let emailField = OCTextField(hint: "Email")
        let addressField = OCTextField(hint: "Address")

        // Add fields to the dialog
        try? customerInfoDialog.addField(key: "name", field: nameField)
        try? customerInfoDialog.addField(key: "email", field: emailField)
        try? customerInfoDialog.addField(key: "address", field: addressField)

        // Get values from the text fields
        let name = nameField.text
        let email = emailField.text
        let address = addressField.text

        if name.isEmpty {
            OCDialog(title: "Input Error", message: "Name cannot be empty.", app: self).show()
            customerInfoDialog.show() // Reopen dialog for correction
            return
        }

        if email.isEmpty {
            OCDialog(title: "Input Error", message: "Email cannot be empty.", app: self).show()
            customerInfoDialog.show() // Reopen dialog for correction
            return
        }

            if address.isEmpty {
            OCDialog(title: "Input Error", message: "Address cannot be empty.", app: self).show()
            customerInfoDialog.show() // Reopen dialog for correction
            return
        }

        do {
            // Create order with customer information
            let order: userOrder = try userOrder(cart: self.userCart)

            // Add this order to overall order history
            self.orderHistory.addOrder(order: order)
            let successDialog = OCDialog(title: "Success", message: "", app: self)

            // Show each new line in the order's description as a new label
            for (index, line) in order.description.components(separatedBy: "\n").enumerated() {
                try successDialog.addField(key: "\(index)", field: OCLabel(text: line))
            }
            successDialog.show()

            // Create new cart
            self.userCart = Cart()
            self.resetItemsVBox()
        } catch {
            if let error = error as? WebError {
                OCDialog(title: "Error placing order", message: error.message, app: self).show()
            }
            // Show the customer information dialog
            customerInfoDialog.show()
        }
    }

     // Method to display order history
    func onShowOrderHistoryButtonClick(button: any OCControlClickable) {
        if orderHistory.allOrders.isEmpty {
            OCDialog(title: "Order History", message: "No orders have been placed yet.", app: self).show()
            return
        }
        let historyDialog = OCDialog(title: "Order History", message: "", app: self)
        // Show each order as a new line in the dialog
        for (index, order) in orderHistory.allOrders.enumerated() {
            do {
                try historyDialog.addField(key: "\(index)", field: OCLabel(text: order.description))
            } catch {
                print("Error adding order to history dialog: \(error)")
            }
        }
        historyDialog.show()
    }

    /// Main method.
    override open func main(app: any OCAppDelegate) -> OCControl {
        // Load the menus.
        let decoder: CSVDecoder = CSVDecoder(configuration: { $0.headerStrategy = .firstLine })

        // Read in the catalogue.
        guard let catalogueText = try? String(contentsOfFile: "catalogueItems.txt") else {
            print("Cannot load catalogueItems.txt")
            exit(0)
        }
        guard let catalogueItems = try? decoder.decode([CatalogueItem].self, from: catalogueText) else {
            print("Cannot decode catalogue.")
            exit(0)
        }

        // Set catalogue.
        guard let menu = try? Catalogue(availableItems: catalogueItems) else {
            print("Cannot create catalogue.")
            exit(0)
        }
        self.catalogue = menu


        // Set up control widths.
        self.cartListView.width = OCSize.percent(100)
        self.cartItemsVBox.width = OCSize.percent(100)
        
        // Set control states.
        self.orderButton.enabled = false

        // Add item names to catalogue.availableItems, so the cart works
        for item in self.catalogue!.availableItems {
            self.cartListView.append(item: item.itemName)
            /// Add OCImageViews to catalogueList
            catalogueList.append(OCImageView(filename: "Baby Blue hoodie.png"))
            catalogueList.append(OCImageView(filename: "Baby Blue t-shirt.png"))
            catalogueList.append(OCImageView(filename: "Black socks.png"))
            catalogueList.append(OCImageView(filename: "Black t-shirt.png"))
            catalogueList.append(OCImageView(filename: "Dark Blue socks.png"))
            catalogueList.append(OCImageView(filename: "Dark Grey hoodie.png"))
            catalogueList.append(OCImageView(filename: "Dark Grey pants.png"))
            catalogueList.append(OCImageView(filename: "Dark Grey t-shirt.png"))
            catalogueList.append(OCImageView(filename: "Eggshell White t-shirt.png"))
            catalogueList.append(OCImageView(filename: "Green socks.png"))
            catalogueList.append(OCImageView(filename: "Khaki pants.png"))
            catalogueList.append(OCImageView(filename: "Light Blue pants.png"))
            catalogueList.append(OCImageView(filename: "Light Grey hoodie.png"))
            catalogueList.append(OCImageView(filename: "Light Grey pants.png"))
            catalogueList.append(OCImageView(filename: "Moss Green pants.png"))
            catalogueList.append(OCImageView(filename: "Navy Blue hoodie.png"))
            catalogueList.append(OCImageView(filename: "Pink hoodie.png"))
            catalogueList.append(OCImageView(filename: "Purple socks.png"))
            catalogueList.append(OCImageView(filename: "White socks.png"))
            catalogueList.append(OCImageView(filename: "White t-shirt.png"))
        }

        // Set up Layout for ImageViews
        var rows: [OCHBox] = []
        let columns = 5

        for rowIndex in 0..<4 {
            var rowItems: [OCImageView] = []
            for columnIndex in 0..<columns {
                let itemIndex = rowIndex * columns + columnIndex
                if itemIndex < catalogueList.count {
                    rowItems.append(catalogueList[itemIndex])
                }
            }
            let hBox = OCHBox(controls: rowItems)
            rows.append(hBox)
        }

        // Create the OCVBox that holds all HBoxes
        let gridLayout = OCVBox(controls: rows)

        // Set up event methods.
        self.cartListView.onChange(self.onCartListViewChange)
        self.addToCartButton.onClick(self.onAddToCartButtonClick)
        self.orderButton.onClick(self.onOrderButtonClick)
        self.showOrderHistoryButton.onClick(self.onShowOrderHistoryButtonClick) 

        // Set up layout.
        let menuVBox = OCVBox(controls: [self.cartListView, self.descriptionLabel, self.cartPriceLabel, self.addToCartButton])
        let cartVBox = OCVBox(controls: [self.cartItemsVBox, self.cartPriceLabel, self.orderButton, self.showOrderHistoryButton])
        let menuHBox = OCHBox(controls: [menuVBox, cartVBox])
        return OCVBox(controls: [menuHBox, gridLayout])
    }
}
SalesWebsiteGUIProgram().start()
