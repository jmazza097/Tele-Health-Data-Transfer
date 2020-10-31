////
////  GraphsViewController.swift
////  ForReal
////
////  Created by Glen Evans on 10/21/20.
////  Copyright © 2020 Jack Mazza. All rights reserved.
////
//
//import UIKit
//import Charts
//
//class graph: UIViewController, ChartViewDelegate{
//    
//
//    
//    var PieChart = PieChartView()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        PieChart.delegate = self
//    }
//    
//    var textGraph = ""
//    lazy var doubleGraph = Double(textGraph)
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        PieChart.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
//        PieChart.center = view.center
//        view.addSubview(PieChart)
//        
//        var entries = [ChartDataEntry]()
//        
//        
//        entries.append(ChartDataEntry(x: 20, y: 3))
//        entries.append(ChartDataEntry(x: 40, y: 50))
//        
//        let set = PieChartDataSet(entries: entries)
//        set.colors = ChartColorTemplates.liberty()
//        let data = PieChartData(dataSet: set)
//        PieChart.data = data
//    }
//    
//    
//}
//
//
//
