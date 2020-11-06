

import UIKit
import HealthKit
import Foundation
import FirebaseUI
import MessageUI
import Charts


class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    var weightString:String = "0.0"
    var weight:Double = 0.0
    var calEaten:String = "0.0"
    var numCalIntake:Double = 0.0
    var caloriesBurned:Double = 0.0
    var BMR:Double = 0.0
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var monthPicker: UIPickerView!
    @IBOutlet weak var dayPicker: UIPickerView!
    @IBOutlet weak var yearPicker: UIPickerView!
    


    class DateHelper {
        
        func getCurrentMonth() -> Int {
            let components = Calendar.current.dateComponents([.month], from: Date())
            return components.month!
        }
        
        func getCurrentDay() -> Int {
            let components = Calendar.current.dateComponents([.day], from: Date())
            return components.day!
        }
        
        func getCurrentYear() -> Int {
            let components = Calendar.current.dateComponents([.year], from: Date())
            return components.year!
        }
        
        
        func getSelectedDate(year: Int, month: Int, day: Int) -> Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            let result = formatter.date(from: "\(year)" + "/" + "\(month)" + "/" + "\(day)")
            
            var selectedDate: Date
            if (result != nil) {
                selectedDate = result!
            }
            else {
                selectedDate = Date()
            }
            
            return selectedDate
        }

    } // end of class DateHelper
    
    var healthStore = HKHealthStore()
    var dateHelper = DateHelper()
    
    var monthArray = [Int]()
    var dayArray = [Int]()
    var yearArray = [Int]()
    
    var selectedYear: Int = 0
    var selectedMonth: Int = 0
    var selectedDay: Int = 0
    
    override func viewDidLoad() {

        
        weightString = weightLabel.text ?? "0.0"
        weight = Double(weightString) ?? 0.0
        calEaten = calIntake.text ?? "0.0"
        numCalIntake = Double(calEaten) ?? 0.0
        caloriesBurned = 0.0
        BMR = 0.0

        
        //perform(#selector(advance), with:nil, afterDelay: 0)
        
        weightLabel.delegate = self // keyboard will be dismissed
        calIntake.delegate = self // keyboard will be dismissed
        
        super.viewDidLoad()
        initializeDateArrays()
        
        // Check to see if the app already has permissions
        if (appIsAuthorized()) {
            displaySteps()
            displayHeartRate()
        } // end if
        
        else {
            // Don't have permission, yet
            handlePermissions()
        } // end else
        
        adjustLabelText()
    } // end of function viewDidLoad

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    } // end of method didReceiveMemoryWarning
    
    
    func handlePermissions() {
        
        // Access Step Count
        let healthKitTypes: Set = [ HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]
        
        // Check Authorization
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            
            if (bool) {
                
                // Authorization Successful
                self.displaySteps()
                self.displayHeartRate()
                
            } // end if
            
        } // end of checking authorization
        
    } // end of func handlePermissions
    
    var steps:Double = 0.0
    var heartRate:Double = 0.0
    
    func displaySteps() {
        
        getSteps { (result) in
            DispatchQueue.main.async {
                
                var stepCount = String(Int(result))
                
                // Did not retrieve proper step count
                if (stepCount == "-1") {
                    
                    // If we do not have permissions
                    if (!self.appIsAuthorized()) {
                        self.stepsLabel.text = "Settings  >  Privacy  >  Health  >  Steps"
                    }
                    
                    // Else, no data to show
                    else {
                        self.stepsLabel.text = "0"
                    } // end else
                    
                    return
                }
                
                if (stepCount.count > 6) {
                    // Add a comma if the user managed to take at least 1,000,000 steps.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 6))
                }
                
                if (stepCount.count > 3) {
                    // Add a comma if the user took at least 1,000 steps.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 3))
                }
                
                self.stepsLabel.text = String(stepCount)
                self.steps = result
                
            }
            
        }
        
        
    } // end of func displaySteps
    
    
    func displayHeartRate() {
        
        getHeartRate{ (result) in
            DispatchQueue.main.async {
                
                let heartRate = String(Int(result))
                
                self.heartRateLabel.text = String(heartRate)
                self.heartRate = result
                
            }
            
        }
        
        
    }
    
    
    func getSteps(completion: @escaping (Double) -> Void) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let selectedDate = dateHelper.getSelectedDate(year: selectedYear, month: selectedMonth, day: selectedDay)
        
        let startOfDay = Calendar.current.startOfDay(for: selectedDate)
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: nil,
                                                options: [.cumulativeSum],
                                                anchorDate: startOfDay,
                                                intervalComponents: interval)
        query.initialResultsHandler = { _, result, error in
            
            var resultCount = -1.0
            
            guard let result = result else {
                completion(resultCount)
                return
            }
            
            result.enumerateStatistics(from: startOfDay, to: selectedDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    // Get steps (they are of double type)
                    resultCount = sum.doubleValue(for: HKUnit.count())
                }
                
                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in
            
            // If new statistics are available
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
        healthStore.execute(query)
        
    } // end of func getSteps
    
    func getHeartRate(completion: @escaping (Double) -> Void) {
        
        let calendar = Calendar.current
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let selectedDate = dateHelper.getSelectedDate(year: selectedYear, month: selectedMonth, day: selectedDay)
        
        let startOfSelectedDate = Calendar.current.startOfDay(for: selectedDate)
        
        let endOfSelectedDate = Calendar.current.date(byAdding: .day, value: 1, to: startOfSelectedDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfSelectedDate, end: endOfSelectedDate, options: [])
        
        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedDate)!

        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(quantityType: heartRateType,
                                                quantitySamplePredicate: predicate,
                                                options: .discreteAverage,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        query.initialResultsHandler = { query, results, error in
                guard let statsCollection = results else { return }

                for statistics in statsCollection.statistics() {
                    guard let quantity = statistics.averageQuantity() else { continue }

                    let beatsPerMinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let value = quantity.doubleValue(for: beatsPerMinuteUnit)

                    let df = DateFormatter()
                    df.dateStyle = .medium
                    df.timeStyle = .none
                    completion(value)
                }
            }

            HKHealthStore().execute(query)
        }
        
    
    
    func appIsAuthorized() -> Bool {
        if (self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized && self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!) == .sharingAuthorized) {
            return true
        }
        else {
            return false
        }
    } // end of method appIsAuthorized
    
    
    func initializeDateArrays() {
        for i in 1...12 {
            monthArray.append(i)
        }
        
        for i in 1...31 {
            dayArray.append(i)
        }
        
        let components = Calendar.current.dateComponents([.year], from: Date())
        let year =  components.year
        
        for i in 2014...year! {
            yearArray.append(i)
        }
        
        
        
        self.monthPicker.delegate = self
        self.monthPicker.dataSource = self
        self.dayPicker.delegate = self
        self.dayPicker.dataSource = self
        self.yearPicker.delegate = self
        self.yearPicker.dataSource = self
        
        self.monthPicker.selectRow(dateHelper.getCurrentMonth() - 1, inComponent: 0, animated: false)
        self.dayPicker.selectRow(dateHelper.getCurrentDay() - 1, inComponent: 0, animated: false)
        self.yearPicker.selectRow(yearArray.count - 1, inComponent: 0, animated: false)
        
        selectedYear = yearArray[self.yearPicker.selectedRow(inComponent: 0)]
        selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
        selectedDay = dayArray[self.dayPicker.selectedRow(inComponent: 0)]
    } // end of method InitializeDateArrays
    
    func adjustLabelText() {
        // Center text within each label
        stepsLabel.textAlignment = NSTextAlignment.center
        
        // Resize font of stepsLabel if it is too large
        stepsLabel.numberOfLines = 1
        stepsLabel.minimumScaleFactor = 0.1
        stepsLabel.adjustsFontSizeToFitWidth = true;
    }
    
    
    func getAvailableDays(month: Int) -> Array<Int> {
        var daysForSpecifiedDay = dayArray
        
        let components = Calendar.current.dateComponents([.month, .day], from: Date())
        let currentDay =  components.day
        let currentMonth =  components.month
        
        var isCurrentMonth = false
        
        // If the selected row in yearPicker is the current year
        if (yearPicker.selectedRow(inComponent: 0) == yearArray.count - 1) {
            
            // If the selected row in monthPicker is the current month
            if (monthPicker.selectedRow(inComponent: 0)+1 == monthArray[currentMonth!-1]) {
                
                isCurrentMonth = true
                daysForSpecifiedDay.removeSubrange(currentDay!...daysForSpecifiedDay.count-1)
                
            }
        }
        
        // If the selected row in monthPicker is not the current month
        if (!isCurrentMonth) {
            let thirtyDayMonths = [4, 6, 9, 11]
            
            // If a 30 Day Month
            if (thirtyDayMonths.contains(month)) {
                daysForSpecifiedDay.removeLast()
            }
            // If February
            else if (month == 2) {
                for _ in 1...3 {
                    daysForSpecifiedDay.removeLast()
                }
            }
        } // end if
        
        return daysForSpecifiedDay
    } // end of func getDays
    
    
    func getAvailableMonths() -> Array<Int> {
        var monthsForSpecifiedYear = monthArray
        
        let component = Calendar.current.dateComponents([.month], from: Date())
        let month =  component.month
        
        // If the selected row is the current year
        if (yearPicker.selectedRow(inComponent: 0) == yearArray.count - 1) {
            for _ in 1...(12-month!) {
                monthsForSpecifiedYear.removeLast()
            }
        }
        return monthsForSpecifiedYear
    }
    
    
    // UIPickerView Methods
    
    // Number of Columns in a Single Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Hide Top and Bottom Border of Each UIPickerView
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    
    // Number of Items in the PickerView
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == yearPicker {
            return yearArray.count
        }
        else if pickerView == monthPicker {
            return getAvailableMonths().count
        }
        else {
            return getAvailableDays(month: (monthPicker.selectedRow(inComponent: 0) + 1)).count
        }
    }
    
    // What Is Displayed
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == yearPicker {
            return String(yearArray[row])
        }
        else if pickerView == monthPicker {
            return String(monthArray[row])
        }
        else {
            return String(dayArray[row])
        }
    }
    
    // Row Changed
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == yearPicker {
            selectedYear = yearArray[self.yearPicker.selectedRow(inComponent: 0)]
            monthPicker.reloadAllComponents()
            selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
            dayPicker.reloadAllComponents()
        }
        else if pickerView == monthPicker {
            selectedMonth = monthArray[self.monthPicker.selectedRow(inComponent: 0)]
            dayPicker.reloadAllComponents()
        }
        selectedDay = dayArray[self.dayPicker.selectedRow(inComponent: 0)]
        displaySteps()
        displayHeartRate()
    }
    
    // Font Size
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view {
            label = v as! UILabel
        }
        label.font = UIFont (name: "Helvetica Neue", size:40)
        if (pickerView == yearPicker) {
            label.text =  String(yearArray[row])
        }
        else if (pickerView == monthPicker) {
            label.text =  String(monthArray[row])
        }
        else {
            label.text =  String(dayArray[row])
        }
        label.textAlignment = .center
        return label
    }
    
    // Set Height of Row of Each UIPickerView
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    

    @IBAction func sendEmail(_ sender: Any) {
        weightString = weightLabel.text ?? "0.0"
        weight = Double(weightString) ?? 0.0
        calEaten = calIntake.text ?? "0.0"
        numCalIntake = Double(calEaten) ?? 0.0
        caloriesBurned = 0.0
        caloriesBurned = steps * 0.05
        let mailComposeViewController = configureMailController()
                if MFMailComposeViewController.canSendMail() {
                    self.present(mailComposeViewController, animated: true, completion: nil)
                } else {
                    showMailError()
                }
            }
            
            func configureMailController() -> MFMailComposeViewController {
                weightString = weightLabel.text ?? "0.0"
                weight = Double(weightString) ?? 0.0
                calEaten = calIntake.text ?? "0.0"
                numCalIntake = Double(calEaten) ?? 0.0
                caloriesBurned = 0.0
                BMR = 0.0
                caloriesBurned = steps * 0.05
                BMR = weight * 11 * 0.95
                let formattedHeartRate = Double(round(1000*heartRate)/1000)
                let formattedCaloriesBurned = Double(round(1000*caloriesBurned)/1000)
                let formattedBMR = Double(round(1000*BMR)/1000)
                
                //Getfirst name for subject
                var name:String = ""
                let user = Auth.auth().currentUser
                if let user = user {
                    let Disname = user.displayName
                    name = Disname ?? ""
                }

                
                let mailComposerVC = MFMailComposeViewController()
                mailComposerVC.mailComposeDelegate = self

                
                mailComposerVC.setToRecipients(["jmazza097@gmail.com"])
                mailComposerVC.setSubject(" \(name)'s Health data for \(selectedMonth) / \(selectedDay) / \(selectedYear)")
                mailComposerVC.setMessageBody("Average Heart Rate: \(formattedHeartRate) \n Steps: \(steps) \n Calories Burned: \(formattedCaloriesBurned) \n Basal Metabolic Rate \(formattedBMR) \n Calorie Intake: \(numCalIntake) \n Patient Weighs \(weight)" , isHTML: false)
                
                return mailComposerVC
            }
            
            func showMailError() {
                let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device could not send email", preferredStyle: .alert)
                let dismiss = UIAlertAction(title: "Ok", style: .default, handler: nil)
                sendMailErrorAlert.addAction(dismiss)
                self.present(sendMailErrorAlert, animated: true, completion: nil)
            }
            
            func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
                controller.dismiss(animated: true, completion: nil)
            }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        caloriesBurned = steps * 0.05
        BMR = weight * 11 * 0.95
        if let segueId = segue.identifier{
            switch segueId{
            case "toGraph":
                if let destination = segue.destination as? graph{
                    destination.caloriesBurned = caloriesBurned
                    destination.steps = steps
                    destination.calorieIntake = numCalIntake
                    destination.BMR = BMR
                }
            case "toCalc":
                if let destination = segue.destination as? CalculationViewController{
                    destination.caloriesBurned = caloriesBurned
                    destination.steps = steps
                    destination.calorieIntake = numCalIntake
                    destination.weight = weight
                    destination.BMR = BMR
                }
            default:
                //nothing to do
                break
            }
        }
    }
    
    @IBOutlet weak var weightLabel: UITextField!
    
    @IBOutlet weak var calIntake: UITextField!
    
    @IBAction func didTapGraph(_ sender: Any) {
        weightString = weightLabel.text ?? "0.0"
        weight = Double(weightString) ?? 0.0
        calEaten = calIntake.text ?? "0.0"
        numCalIntake = Double(calEaten) ?? 0.0
        caloriesBurned = 0.0
        BMR = 0.0
    }
    
    @IBAction func didTapCalc(_ sender: Any) {
        weightString = weightLabel.text ?? "0.0"
        weight = Double(weightString) ?? 0.0
        calEaten = calIntake.text ?? "0.0"
        numCalIntake = Double(calEaten) ?? 0.0
        caloriesBurned = 0.0
        BMR = 0.0
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        weightLabel.resignFirstResponder()
        calIntake.resignFirstResponder()
        return true
    }
    

} // end of class ViewController


//graph view controller
class graph: UIViewController, ChartViewDelegate{
    
    var caloriesBurned:Double = 0.0
    var calorieIntake:Double = 0.0
    var steps:Double = 0.0
    var BMR:Double = 0.0
    

    var PieChart = PieChartView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PieChart.delegate = self
    }
    
    var textGraph = ""
    lazy var doubleGraph = Double(textGraph)
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        PieChart.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        PieChart.center = view.center
        view.addSubview(PieChart)
        
        var entries = [ChartDataEntry]()
        
        //entries.append(ChartDataEntry(x: 20, y: steps))
        entries.append(ChartDataEntry(x: 60, y: calorieIntake))
        entries.append(ChartDataEntry(x: 40, y: caloriesBurned))
        entries.append(ChartDataEntry(x: 80, y: BMR))
        
        let chartDataSet = PieChartDataSet(entries: entries, label: "Caloric Intake, Calories Burned, BMR")
        
        //let set = PieChartDataSet(entries: entries)
        chartDataSet.colors = ChartColorTemplates.material()
        let data = PieChartData(dataSet: chartDataSet)
        PieChart.data = data
    }
    
    
}
class CalculationViewController: UIViewController {
    var caloriesBurned = 0.0
    var calorieIntake = 0.0
    var steps = 0.0
    var weight:Double = 0.0
    var BMR:Double = 0.0


    override func viewDidLoad() {
        super.viewDidLoad()
        calBurned.text = String(caloriesBurned)
        BMRLabel.text = String(BMR)
        warnings()

        // Do any additional setup after loading the view.
    }
    func warnings(){
        if steps<1000.0 {
            stepWarning.text = "Not Enough Steps. Try Walking More!"
        }
        if calorieIntake<800.0 {
            calWarning.text = "Not Enough Calories. Try Eating More!"
        }
    }

    @IBOutlet weak var calBurned: UILabel!
    
    @IBOutlet weak var BMRLabel: UILabel!
    
    @IBOutlet weak var stepWarning: UILabel!
    // @IBOutlet weak var stepWarning: UILabel!
    
    @IBOutlet weak var calWarning: UILabel!
    //@IBOutlet weak var calWarning: UILabel!
    
}



