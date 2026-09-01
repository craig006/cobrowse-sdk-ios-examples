import UIKit

class UnredactionRegistry {
    static let shared = UnredactionRegistry()

    private var unredacted = NSHashTable<UIView>.weakObjects()

    var all: [UIView] {
        unredacted.allObjects
    }

    func add(_ view: UIView) {
        unredacted.add(view)
    }

    func remove(_ view: UIView) {
        unredacted.remove(view)
    }
}
