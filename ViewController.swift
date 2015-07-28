//
//  ViewController.swift
//  SwiftTuneSearch
//
//  Created by Erik Hoversten on 13.07.15.
//  Copyright (c) 2015 EverProductions. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var serverReach : Reachability?
    var searchURL = "itunes.apple.com"
    var serverAvailable = false
    var tuneArray = [TuneSearch]()
    
    @IBOutlet private var searchTextField : UITextField!
    @IBOutlet private var searchLabel : UILabel!
    @IBOutlet private var searchButton : UIButton!
    @IBOutlet var tuneCollectionView : UICollectionView!
    
    // MARK: - Interactivity Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool  {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func searchButtonPressed(sender: UIButton)  {
        println("search")
        let searchTerm = searchTextField.text.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let url = NSURL(string: "https://\(searchURL)/search?term=\(searchTerm)")
        let urlRequest = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        let queue = NSOperationQueue()
        if serverAvailable  {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                if data != nil  {   // do we have data?
                    var err : NSError?
                    let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as! NSDictionary
                    if err != nil  {
                        println("Error:\(err)")
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    } else {
                        var tempTuneDictArray = jsonResult.objectForKey("results") as! [NSDictionary]
                        for resultDict in tempTuneDictArray {
                            var result = TuneSearch()
                            result.artistNameLabel = resultDict.objectForKey("artistName") as! String
                            result.artistAlbum = resultDict.objectForKey("collectionName") as! String
                            result.trackNameLabel = resultDict.objectForKey("trackName") as! String
                            let remoteFilename = resultDict.objectForKey("artworkUrl100") as! String
                            result.musicImageFilename = remoteFilename.lastPathComponent
                            self.tuneArray.append(result)
                            if self.fileIsLocal(result.musicImageFilename)  {
                            } else {
                                self.getImageFromServer(result.musicImageFilename, remoteFilename: remoteFilename)
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tuneCollectionView.reloadData()
                        }
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                 
                } else {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            })
        }
    }
    
    // MARK: - Server Methods
    
    func reachabilityChanged(note: NSNotification)   {
        let reach = note.object as! Reachability
        if reach.currentReachabilityStatus().value == NotReachable.value   {
            serverAvailable = false
           
        } else {
            serverAvailable = true
            
        }
    }
    
    func getDocumentPathForFilename(filename: String)  -> String  {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let filePath = documentsPath.stringByAppendingPathComponent(filename)
        return filePath
    }
    
    func fileIsLocal(filename: String) -> Bool   {
        var fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(getDocumentPathForFilename(filename))
    }
    
    func getImageFromServer(localFilename: String, remoteFilename: String)   {
        let remoteURL = NSURL(string: remoteFilename)
        let imageData = NSData(contentsOfURL: remoteURL!)
        let imageTemp : UIImage? = UIImage(data: imageData!)
        if let image = imageTemp  {
            imageData!.writeToFile(getDocumentPathForFilename(localFilename), atomically: false)
        }
    }
    
    // MARK: - Collection View Methods
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(165, 165)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tuneArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell : TuneCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! TuneCollectionViewCell
        let currentResult = tuneArray[indexPath.row]
        cell.artistNameLabel!.text = currentResult.artistNameLabel
        cell.artistAlbum!.text = currentResult.artistAlbum
        cell.trackNameLabel!.text = currentResult.trackNameLabel
        cell.albumImageView!.image = UIImage(named: getDocumentPathForFilename(currentResult.musicImageFilename))
        return cell
    }
    
    
    // MARK: - Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        serverReach = Reachability(hostName: searchURL)
        serverReach?.startNotifier()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: kReachabilityChangedNotification, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
 
    }


}

