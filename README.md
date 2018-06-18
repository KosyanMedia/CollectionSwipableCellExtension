# CollectionSwipableCellExtension
Swipable buttons for UICollectionView and UITableView

The extension for UICollectionView and UITableView which appends buttons to a cell are shown on cell swiping. Also supports swipe to delete gesture.
It doesn’t require subclassing of cell class, it’s more useful for case when third-party cell already is used.
The buttons UI is fully customised by providing own layout.

Install

Carthage

Using

```swift
// import framework
import CollectionSwipableCellExtension

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    // make a strong reference
    private var swipableExtension: CollectionSwipableCellExtension?

    override func viewDidLoad() {
        super.viewDidLoad()

        // initialize with UITableView or UICollectionView
        swipableExtension = CollectionSwipableCellExtension(with: tableView)
        // set a delegate for telling whoch cells are swipable and set layout
        swipableExtension?.delegate = self
        // enable/disable swiping functionality for all cells
        swipableExtension?.isEnabled = true
    }

}

extension ViewController: CollectionSwipableCellExtensionDelegate {

    // tell that cell on indexPath is swipable
    func isSwipable(itemAt indexPath: IndexPath) -> Bool {
        return true
    }

    // return swipable buttons layout, CollectionSwipableCellOneButtonLayout is default sample layout, you can make yourself
    func swipableActionsLayout(forItemAt indexPath: IndexPath) -> CollectionSwipableCellLayout? {
        let actionLayout = CollectionSwipableCellOneButtonLayout(buttonWidth: 100, insets: .zero, direction: .leftToRight)
        actionLayout.action = { [weak self] in
            //do something
        }

        return actionLayout
    }

}    
```
