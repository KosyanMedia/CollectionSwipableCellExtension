# CollectionSwipableCellExtension
Swipable buttons for UICollectionView and UITableView

The extension for UICollectionView and UITableView which appends buttons to a cell are shown on cell swiping. Also supports swipe to delete gesture.
It doesn’t require subclassing of cell class, it’s more useful for case when third-party cell already is used.
The buttons UI is fully customised by providing own layout.

Install

Carthage

cocoapods

Requirements

Using

Initialize extension object and set delegate

isEnabled property allow activate/deactivate functionality

```swift
swipableExtension = CollectionSwipableCellExtension(with: tableView)
swipableExtension?.delegate = self
swipableExtension?.isEnabled = true
```

Implement methods od CollectionSwipableCellExtensionDelegate protocol, which return layout for buttons and define which cells are swipeble.

```swift
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
```

Call resetSwipableActions() in order to solve problems with cell's reuse

```swift
func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.resetSwipableActions()
}
```

About layout customization
