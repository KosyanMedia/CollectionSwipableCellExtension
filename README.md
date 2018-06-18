# CollectionSwipableCellExtension
Swipable buttons for UICollectionView and UITableView

The extension for UICollectionView and UITableView which appends buttons to a cell are shown on cell swiping. Also supports swipe to delete gesture.
It doesn’t require subclassing of cell class, it’s more useful for case when third-party cell already is used.
The buttons UI is fully customised by providing own layout.

Install

Carthage

Using

    import CollectionSwipableCellExtension

    class ViewController: UIViewController {

        @IBOutlet weak var tableView: UITableView!

        private var swipableExtension: CollectionSwipableCellExtension?

        override func viewDidLoad() {
            super.viewDidLoad()

            swipableExtension = CollectionSwipableCellExtension(with: tableView)
            swipableExtension?.delegate = self
            swipableExtension?.isEnabled = true
        }

    }

    extension ViewController: CollectionSwipableCellExtensionDelegate {

        func isSwipable(itemAt indexPath: IndexPath) -> Bool {
            return true
        }

        func swipableActionsLayout(forItemAt indexPath: IndexPath) -> CollectionSwipableCellLayout? {
            let actionLayout = CollectionSwipableCellOneButtonLayout(buttonWidth: 100, insets: .zero, direction: .leftToRight)
            actionLayout.action = { [weak self] in
                self?.deleteCell(atIndexPath: indexPath)
            }

            return actionLayout
        }

    }

