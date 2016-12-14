//
//  IssuerTableViewController.swift
//  wallet
//
//  Created by Chris Downie on 10/27/16.
//  Copyright © 2016 Learning Machine, Inc. All rights reserved.
//

import UIKit
import BlockchainCertificates

private let issuerSummaryCellReuseIdentifier = "IssuerSummaryTableViewCell"
private let certificateCellReuseIdentifier = "UITableViewCell +certificateCellReuseIdentifier"
private let noCertificatesCellReuseIdentififer = "NoCertificateTableViewCell"

fileprivate enum Sections : Int {
    case issuerSummary = 0
    case certificates
    case count
}

class IssuerTableViewController: UITableViewController {
    public var managedIssuer : ManagedIssuer? {
        didSet {
            self.title = managedIssuer?.issuer?.name
        }
    }
    public var certificates : [Certificate] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: certificateCellReuseIdentifier)
        tableView.register(UINib(nibName: "IssuerSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: issuerSummaryCellReuseIdentifier)
        tableView.register(UINib(nibName: "NoCertificatesTableViewCell", bundle: nil), forCellReuseIdentifier: noCertificatesCellReuseIdentififer)
        
        tableView.estimatedRowHeight = 87
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        tableView.separatorColor = UIColor(red:0.87, green:0.88, blue:0.90, alpha:1.0)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.issuerSummary.rawValue {
            return 1
        } else if section == Sections.certificates.rawValue {
            if certificates.isEmpty {
                return 1
            } else {
                return certificates.count
            }
        }
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let returnedCell : UITableViewCell!
        
        switch indexPath.section {
        case Sections.issuerSummary.rawValue:
            let summaryCell = tableView.dequeueReusableCell(withIdentifier: issuerSummaryCellReuseIdentifier) as! IssuerSummaryTableViewCell
            if let issuer = managedIssuer?.issuer {
                summaryCell.issuerImageView.image = UIImage(data: issuer.image)
            }
            returnedCell = summaryCell
        case Sections.certificates.rawValue:
            if certificates.isEmpty {
                returnedCell = tableView.dequeueReusableCell(withIdentifier: noCertificatesCellReuseIdentififer)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: certificateCellReuseIdentifier)!
                let certificate = certificates[indexPath.row]
                cell.textLabel?.text = certificate.title
                cell.detailTextLabel?.text = certificate.subtitle
                
                returnedCell = cell
            }
        default:
            returnedCell = UITableViewCell()
        }
        
        return returnedCell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == Sections.certificates.rawValue {
            return "Certificates"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Sections.certificates.rawValue {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard indexPath.section == Sections.certificates.rawValue else {
            return nil
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
            let deletedCertificate : Certificate! = self?.certificates.remove(at: indexPath.row)
            
            let documentsDirectory = Paths.certificatesDirectory
            let certificateFilename = deletedCertificate.assertion.uid
            let filePath = URL(fileURLWithPath: certificateFilename, relativeTo: documentsDirectory)
            
            let coordinator = NSFileCoordinator()
            var coordinationError : NSError?
            coordinator.coordinate(writingItemAt: filePath, options: [.forDeleting], error: &coordinationError, byAccessor: { (file) in
                
                do {
                    try FileManager.default.removeItem(at: filePath)
                    tableView.reloadData()
                } catch {
                    print(error)
                    self?.certificates.insert(deletedCertificate, at: indexPath.row)
                    
                    let alertController = UIAlertController(title: "Couldn't delete file", message: "Something went wrong deleting that certificate.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alertController, animated: true, completion: nil)
                }
            })
            
            if let error = coordinationError {
                print("Coordination failed with \(error)")
            } else {
                print("Coordination went fine.")
            }
            
        }
        return [ deleteAction ]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == Sections.certificates.rawValue else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let selectedCertificate = certificates[indexPath.row]
        let controller = CertificateViewController(certificate: selectedCertificate)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == Sections.certificates.rawValue {
            cell.separatorInset = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 0)
        }
    }
}
