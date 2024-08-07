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

    /// Create an item with validation
    ///
    /// - Parameters:
    ///     - itemName: name of the item in the catalogue
    ///     - itemPrice: price of the item in the catalogue
    init(itemName: String, itemPrice: Double) throws{
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
    }

    // Conformance to Codable.
    enum CodingKeys : Int, CodingKey {
        case itemName = 0
        case itemPrice = 1
    }

    /// Catalogue Item's price as a string formatted in NZD
    var priceDescription: String {
        let numberDescription: String = String(format: "%.2f", self.itemPrice)
        return "$\(numberDescription)"
    }

    /// Compatibility with CustomStringConvertible
    var itemDescription: String {
        return "\(self.itemName) .......... \(self.priceDescription)"
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
    let CartLimit: Int = 5

    /// The user's items. Items will be added to/removed from it.
    var userItems: [CatalogueItem] = []

/// Get cart's total price as string formatted for NZD.
var totalPriceString: String {
    // Calculate price of ALL items in cart.
    var GrandTotal: Double = 0.0
    for item in self.userItems { GrandTotal = GrandTotal + item.itemPrice }

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
        guard self.userItems.count != CartLimit else {
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

/// start of GUI Program
class SalesWebsiteGUIProgram: OCApp {
// Catalogue from where user selects items to order
var catalogue: Catalogue? = nil

/// User's cart. It begins empty.
var cart: Cart = Cart()

    // GUI controls for program
    let catalogueListView = OCListView()
    let priceTag = OCLabel(text: "")
    let addToCartButton = OCButton(text: "Add to Cart")
let cartItemsVBox = OCVBox(controls: [])
let cartPriceLabel = OCLabel(text: "")

// Track remove buttons.
var totalRemoveButtons: [OCButton] = []


    /// Update labels when new catalogue item is selected by user.
    func onCatalogueListViewChange(listView: any OCControlChangeable, selected: OCListItem) {
        // Get item from catalogue.
        guard let item: CatalogueItem = self.catalogue!.FindItem(NameToSearch: selected.text) else {
            // If no item can be loaded, do nothing.
            return
        }

        // Otherwise, update labels.
        self.priceTag.text = item.priceDescription
    }

    /// Recreate items VBox when anything is added or removed.
    func resetItemsVBox() {
        // Reset GUI.
        self.cartItemsVBox.empty()
        self.totalRemoveButtons = []

        for item in self.cart.userItems {
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
        self.cartPriceLabel.text = self.cart.totalPriceString
    }

    /// Add selected item to cart.
    func onAddToCartButtonClick(button: any OCControlClickable) {
        // Check a selection has been made by user.
        guard let selected = self.catalogueListView.selectedItem else {
            // If an item hasn't been selected by user, do nothing.
            return
        }

        let itemName: String = selected.text

        // Add item to cart.
        do {
            try self.cart.addItem(itemX: itemName, fromCatalogue: self.catalogue!)
            // Add the item to the GUI.
            self.resetItemsVBox()
            OCDialog(title: "Success", message: "Added \(itemName)!", app: self).show()
            // If item not successfully added, throw WebError to user.
        } catch {
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
            try self.cart.removeItem(RemoveItemName: self.cart.userItems[index].itemName)

            // Remove item from GUI.
            self.resetItemsVBox()
        } catch {
            if let error = error as? WebError {
                OCDialog(title: "Remove error", message: error.message, app: self).show()
            }
        }
    }

    /// Main method.
    override open func main(app: any OCAppDelegate) -> OCControl {
        // Load the menus.
        let decoder: CSVDecoder = CSVDecoder(configuration: { $0.headerStrategy = .firstLine })

        // Read in the catalogue.
        guard let catalogueText = try? String(contentsOfFile: "catalogueItems.txt"),
        let catalogueItems = try? decoder.decode([CatalogueItem].self, from: catalogueText) else {
            print("Cannot load catalogue.")
            exit(0)
        }

        // Set menu.
        guard let menu = try? Catalogue(availableItems: catalogueItems) else {
            print("Cannot create menu.")
            exit(0)
        }
        self.catalogue = menu


        // Set up control widths.
        self.catalogueListView.width = OCSize.percent(100)
        self.cartItemsVBox.width = OCSize.percent(100)

        // Add catalogue items to catalogue list view.
        for item in self.catalogue!.availableItems {
            self.catalogueListView.append(item: item.itemName)
        }
// Set up event methods.
self.catalogueListView.onChange(self.onCatalogueListViewChange)
self.addToCartButton.onClick(self.onAddToCartButtonClick)


        // Set up layout.
        let menuVBox = OCVBox(controls: [self.catalogueListView, self.cartPriceLabel, self.addToCartButton])
        let cartVBox = OCVBox(controls: [self.cartItemsVBox, self.cartPriceLabel])
        return OCHBox(controls: [menuVBox, cartVBox])
    }
}
SalesWebsiteGUIProgram().start()
