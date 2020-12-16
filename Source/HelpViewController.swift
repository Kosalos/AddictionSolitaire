import UIKit

let help = """
The goal in Addiction Solitaire is to sort all four rows in ascending order:
2 to K.

Each row must be of the same suit.

After the deal, the Aces are removed to create 4 blank positions.

Cards can be moved into blank positions one at a time.

Tap on an empty position to move the correct card there.
Tap on a card to move it next to it's correct neighbor (if possible).

A Two of any suit can be placed into the leftmost column;
once there, it sets the suit for the entire row.

No card can be moved to the right of a King.
"""

class HelpViewController: UIViewController {

    @IBOutlet var helptext: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = CGSize(width: 550,height: 700)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        helptext.text = help
    }
}
