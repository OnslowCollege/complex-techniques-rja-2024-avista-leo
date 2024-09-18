// Avista + Leo Inc.
//
// Created by Avista Goswami and Leo Evans
// Established on 23/06/2024

import Foundation
import OCGUI
import CodableCSV

/// Represents an error that can be raised in the application.
struct WebError: Error {
    /// Message to be displayed to the user.
    let message: String
}

/// Represents an item within the catalogue.
struct CatalogueItem: Codable, CustomStringConvertible {
    /// The minimum allowable price for items in the catalogue.
    static let minPrice: Double = 0.01

    /// The name of the item.
    let itemName: String

    /// The item's price in NZD.
    let itemPrice: Double

    /// Description of the product.
    let productInfo: String

    /// Initializes a CatalogueItem after validating its properties.
    ///
    /// - Parameters:
    ///     - itemName: The name of the item in the catalogue.
    ///     - itemPrice: The price assigned to the item in the catalogue.
    ///     - productInfo: Information about the product that users can view.
    init(itemName: String, itemPrice: Double, productInfo: String) throws {
        // Ensure the itemName is not empty.
        if itemName.isEmpty {
            throw WebError(message: "Items in the catalogue must have at least one character in their name.")
        }
        self.itemName = itemName

        // Validate that itemPrice is a positive number.
        if itemPrice < CatalogueItem.minPrice {
            throw WebError(message: "Items cannot be given away for free or paid for by customers.")
        }
        self.itemPrice = itemPrice

        // Ensure productInfo is not empty.
        if productInfo.isEmpty {
            throw WebError(message: "Product information must contain at least one character.")
        }
        self.productInfo = productInfo
    }

    // Conformance to Codable.
    enum CodingKeys: Int, CodingKey {
        case itemName = 0
        case itemPrice = 1
        case productInfo = 2
    }

    /// Returns the price formatted as a string in NZD.
    var priceDescription: String {
        String(format: "$%.2f", itemPrice)
    }

    /// Provides a description of the product.
    var productDescription: String {
        return productInfo
    }

    /// Implements CustomStringConvertible.
    var itemDescription: String {
        return "\(itemName)..... \(productInfo).......... \(priceDescription)"
    }

    var description: String {
        return itemDescription
    }
}

/// Represents a collection of items available for sale on the website.
struct Catalogue: CustomStringConvertible {
    /// The items available for purchase by users.
    let availableItems: [CatalogueItem]

    init(availableItems: [CatalogueItem]) throws {
        // Verify that at least one item is in the catalogue.
        if availableItems.isEmpty {
            throw WebError(message: "The catalogue must contain at least one item for sale.")
        }
        self.availableItems = availableItems
    }

    /// Searches for an item by its name in the catalogue.
    ///
    /// - Parameters:
    ///   - itemName: The name of the item to search for.
    ///
    /// - Returns: The found CatalogueItem if available, otherwise nil.
    func FindItem(NameToSearch itemName: String) -> CatalogueItem? {
        // Locate the first item that matches the name in the array.
        return availableItems.first(where: { $0.itemName.lowercased() == itemName.lowercased() })
    }

    /// Implements CustomStringConvertible.
    var description: String {
        var builder = "MENU\n"
        for (index, availableItem) in availableItems.enumerated() {
            builder += "\(index + 1). \(availableItem)\n"
        }
        return builder
    }
}

/// Represents items that the user intends to order from the catalogue.
struct Cart: CustomStringConvertible {
    /// The maximum number of items a user can order in one transaction.
    static let cartLimit: Int = 5

    /// The items in the user's cart, which can be modified.
    var userItems: [CatalogueItem] = []

    /// Returns the total price of the cart as a formatted string in NZD.
    var totalPriceString: String {
        let grandTotal = userItems.reduce(0.0) { $0 + $1.itemPrice }
        return String(format: "$%.2f", grandTotal)
    }

    /// Adds an item to the cart if it hasn't reached the limit.
    ///
    /// - Parameters:
    ///   - itemName: The name of the item to be added.
    ///   - catalogue: The catalogue to search for the item.
    mutating func addItem(itemX name: String, fromCatalogue catalogue: Catalogue) throws {
        // Ensure the cart hasn't reached its maximum capacity.
        guard userItems.count < Cart.cartLimit else {
            throw WebError(message: "Sorry, your cart is full.")
        }

        // Look for the item in the catalogue.
        guard let item = catalogue.FindItem(NameToSearch: name) else {
            throw WebError(message: "The item '\(name)' was not found in the catalogue.")
        }

        // Add the item to the cart.
        userItems.append(item)
    }

    /// Removes an item from the cart if it exists.
    ///
    /// - Parameters:
    ///   - itemName: The name of the item to remove.
    mutating func removeItem(RemoveItemName name: String) throws {
        // Locate the index of the item.
        guard let itemIndex = userItems.firstIndex(where: { $0.itemName.lowercased() == name.lowercased() }) else {
            throw WebError(message: "The item '\(name)' was not found in your cart.")
        }

        // Remove the found item.
        userItems.remove(at: itemIndex)
    }

    /// Implements CustomStringConvertible.
    var description: String {
        var builder = "CART\n"
        for (index, availableItem) in userItems.enumerated() {
            builder += "\(index + 1). \(availableItem)\n"
        }
        builder += "TOTAL: \(totalPriceString)\n"
        return builder
    }
}

/// Represents a completed order placed by the user.
struct userOrder: CustomStringConvertible {
    /// The items from the cart that are part of the user's order.
    let cart: Cart

    init(cart: Cart) throws {
        // Ensure the cart contains items.
        guard !cart.userItems.isEmpty else {
            throw WebError(message: "Your order cannot be empty.")
        }
        self.cart = cart
    }

    /// Implements CustomStringConvertible.
    var description: String {
        // Split the cart description into lines.
        let cartLines = cart.description.components(separatedBy: "\n")
        return cartLines[1...].joined(separator: "\n") // Exclude the first line.
    }
}

/// Maintains the history of orders placed by the user.
struct userOrderHistory: CustomStringConvertible {
    /// The collection of orders made by the user.
    var allOrders: [userOrder] = []

    /// Adds a new order to the history.
    mutating func addOrder(order: userOrder) {
        allOrders.append(order)
    }

    /// Implements CustomStringConvertible.
    var description: String {
        var builder = "ORDERS\n"
        for order in allOrders {
            builder += order.description + "\n"
        }
        return builder
    }
}

/// Main class for the GUI application.
class SalesWebsiteGUIProgram: OCApp {
    
    // Catalogue from which users select items to order.
    var catalogue: Catalogue? = nil

    /// The user's cart, starting off empty.
    var userCart: Cart = Cart()

    /// The user's order history, starting off empty.
    var orderHistory: userOrderHistory = userOrderHistory()

    // GUI controls for the application.
    let cartListView = OCListView()
    let priceTag = OCLabel(text: "")
    let addToCartButton = OCButton(text: "Add to Cart")
    let cartItemsVBox = OCVBox(controls: [])
    let cartPriceLabel = OCLabel(text: "")
    let orderButton = OCButton(text: "Confirm Order: ")
    var catalogueList: [OCImageView] = []
    let descriptionLabel = OCLabel(text: "")

    // List to track remove buttons.
    var totalRemoveButtons: [OCButton] = []

    /// Updates labels when a new catalogue item is selected by the user.
    func onCartListViewChange(listView: any OCControlChangeable, selected: OCListItem) {
        // Retrieve the selected item from the catalogue.
        guard let item: CatalogueItem = catalogue?.FindItem(NameToSearch: selected.text) else {
            print("No item found in catalogue upon selection.")
            return
        }

        // Update the labels with details of the selected item.
        priceTag.text = item.priceDescription
        descriptionLabel.text = item.productDescription
    }

    /// Rebuilds the items VBox when items are added or removed.
    func resetItemsVBox() {
        // Clear the current GUI.
        cartItemsVBox.empty()
        totalRemoveButtons = []

        for item in userCart.userItems {
            // Create a label and remove button for each item in the cart.
            let label = OCLabel(text: item.itemName)
            let buttonRemove = OCButton(text: "➖")
            buttonRemove.onClick(onRemoveButtonClick)
            totalRemoveButtons.append(buttonRemove)

            // Arrange cart items and controls horizontally.
            let cartItemHBox = OCHBox(controls: [label, buttonRemove])
            cartItemHBox.width = OCSize.percent(100)
            cartItemHBox.height = OCSize.pixels(50)
            cartItemsVBox.append(control: cartItemHBox)
        }

        // Update the cart's total price in the GUI.
        cartPriceLabel.text = userCart.totalPriceString

        // Enable the order button if there are items in the cart.
        orderButton.enabled = !userCart.userItems.isEmpty

        // Disable the add to cart button if the cart is full.
        addToCartButton.enabled = userCart.userItems.count < Cart.cartLimit
    }

    /// Adds the selected item to the cart.
    func onAddToCartButtonClick(button: any OCControlClickable) {
        // Ensure the user has made a selection.
        guard let selectedIndex = cartListView.selectedIndex else {
            print("No item selected.")
            return
        }

        let itemName: String = catalogue!.availableItems[selectedIndex].itemName

        // Attempt to add the item to the cart.
        do {
            try userCart.addItem(itemX: itemName, fromCatalogue: catalogue!)
            resetItemsVBox() // Refresh the items display.
            OCDialog(title: "Success", message: "Added \(itemName)!", app: self).show()
        } catch {
            print(error)
            if let error = error as? WebError {
                OCDialog(title: "Add error", message: error.message, app: self).show()
            }
        }
    }

    /// Removes an item from the user's cart.
    func onRemoveButtonClick(button: any OCControlClickable) {
        do {
            let button = button as! OCButton
            guard let index = totalRemoveButtons.firstIndex(where: { $0.pythonObject == button.pythonObject }) else { return }
            try userCart.removeItem(RemoveItemName: userCart.userItems[index].itemName)

            // Refresh the item display in the GUI.
            resetItemsVBox()

            // Update the cart's total price display.
            cartPriceLabel.text = userCart.totalPriceString

        } catch {
            if let error = error as? WebError {
                OCDialog(title: "Remove error", message: error.message, app: self).show()
            }
        }
    }
    
    /// Handles the process of placing an order.
    func onOrderButtonClick(button: any OCControlClickable) {
        do {
            // Create a new order from the current cart.
            let order: userOrder = try userOrder(cart: userCart)

            // Add this order to the user's order history.
            orderHistory.addOrder(order: order)
            let dialog = OCDialog(title: "Success", message: "", app: self)
            // Display each line of the order's description.
            for (index, line) in order.description.components(separatedBy: "\n").enumerated() {
                try dialog.addField(key: "\(index)", field: OCLabel(text: line))
            }
            dialog.show()

            // Clear the current cart.
            userCart = Cart()
            resetItemsVBox()
        } catch {
            if let error = error as? WebError {
                OCDialog(title: "Add error", message: error.message, app: self).show()
            }
        }
    }

    /// Main method that runs the application.
    override open func main(app: any OCAppDelegate) -> OCControl {
        // Load the catalogue from a CSV file.
        let decoder: CSVDecoder = CSVDecoder(configuration: { $0.headerStrategy = .firstLine })

        // Read the catalogue data.
        guard let catalogueText = try? String(contentsOfFile: "catalogueItems.txt") else {
            print("Unable to load catalogueItems.txt")
            exit(0)
        }
        guard let catalogueItems = try? decoder.decode([CatalogueItem].self, from: catalogueText) else {
            print("Unable to decode the catalogue.")
            exit(0)
        }

        // Initialize the catalogue.
        guard let menu = try? Catalogue(availableItems: catalogueItems) else {
            print("Unable to create the catalogue.")
            exit(0)
        }
        catalogue = menu

        // Configure the layout of controls.
        cartListView.width = OCSize.percent(100)
        cartItemsVBox.width = OCSize.percent(100)

        // Set the initial state of the controls.
        orderButton.enabled = false

         // Add item names to catalogue.availableItems, so the cart works
        for item in catalogue!.availableItems {
            cartListView.append(item: item.itemName)
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

        // Set up the layout for the image views.
        var rows: [OCHBox] = []
        let columns = 14

        for rowIndex in 0..<2 {
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

        // Create the VBox that holds all rows of image views.
        let gridLayout = OCVBox(controls: rows)

        // Set event handlers for controls.
        cartListView.onChange(onCartListViewChange)
        addToCartButton.onClick(onAddToCartButtonClick)
        orderButton.onClick(onOrderButtonClick)

        // Organize the layout of the GUI.
        let menuVBox = OCVBox(controls: [cartListView, descriptionLabel, cartPriceLabel, addToCartButton])
        let cartVBox = OCVBox(controls: [cartItemsVBox, cartPriceLabel, orderButton])
        let menuHBox = OCHBox(controls: [menuVBox, cartVBox])
        return OCVBox(controls: [menuHBox, gridLayout])
    }
}
SalesWebsiteGUIProgram().start()
