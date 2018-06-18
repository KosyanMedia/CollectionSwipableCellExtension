# CollectionSwipableCellExtension
Swipable buttons for UICollectionView and UITableView

The extension for UICollectionView and UITableView which appends buttons to a cell are shown on cell swiping. Also supports swipe to delete gesture.
It doesn’t require subclassing of cell class, it’s more useful for case when third-party cell already is used.
The buttons UI is fully customised by providing own layout.

Install

Carthage

Using

```swift
import CollectionSwipableCellExtension // import framework

class ViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!

	private var swipableExtension: CollectionSwipableCellExtension? // make a strong reference

	override func viewDidLoad() {
		super.viewDidLoad()

		swipableExtension = CollectionSwipableCellExtension(with: tableView) // initialize with UITableView or UICollectionView
		swipableExtension?.delegate = self // set a delegate for telling whoch cells are swipable and set layout
		swipableExtension?.isEnabled = true // enable/disable swiping functionality for all cells
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
