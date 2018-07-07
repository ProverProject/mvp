import UIKit

class VideoQualityViewController: UITableViewController {
    private let availablePresets: [AVOutputSettingsPreset] =
            AVOutputSettingsAssistant.availableOutputSettingsPresets()

    private var currentIndexPath = IndexPath()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 48
        tableView.tableFooterView = UIView()

        currentIndexPath = IndexPath(row: availablePresets.index(of: Settings.currentVideoPreset)!,
                                     section: 0)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return availablePresets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let preset = availablePresets[indexPath.row]
        let videoQuality = Settings.videoQuality(forPreset: preset)
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoQualityTableViewCell", for: indexPath)

        cell.textLabel!.text = "\(videoQuality.width) × \(videoQuality.height)"

        if indexPath != currentIndexPath {
            cell.textLabel!.font = .forDeselectedItem
            cell.accessoryType = .none
        }
        else {
            cell.textLabel!.font = .forSelectedItem
            cell.accessoryType = .checkmark
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


// MARK: - UITableViewDelegate
extension VideoQualityViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath != currentIndexPath {
            let prevIndexPath = currentIndexPath
            currentIndexPath = indexPath

            let prevCell = tableView.cellForRow(at: prevIndexPath)
            let currentCell = tableView.cellForRow(at: currentIndexPath)

            prevCell?.textLabel!.font = .forDeselectedItem
            prevCell?.accessoryType = .none

            currentCell!.textLabel!.font = .forSelectedItem
            currentCell!.accessoryType = .checkmark

            Settings.currentVideoPreset = availablePresets[currentIndexPath.row]
        }

        presentingViewController!.dismiss(animated: true, completion: nil)
    }
}

fileprivate extension UIFont {
    static var forSelectedItem: UIFont { return UIFont.boldSystemFont(ofSize: 14) }
    static var forDeselectedItem: UIFont { return UIFont.systemFont(ofSize: 14) }
}
