
//  Webservice.swift
//  AutoMint
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices

class Webservice: NSObject {
    
    // propetry
    
    var parmeters   : NSDictionary!
    var userData    : Int!
    
    var userStoreg  : NSMutableDictionary!
    
    func RequestForGet(strUrl:String,successHandler:(response:
        NSDictionary,isSuccess:Bool)-> Void ){
        
        if SharedClass.isReachable {
            
            let boundary = generateBoundaryString()
            
            let url = NSURL(string: strUrl)!
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                if error != nil {
                    
                    successHandler(response: NSDictionary(), isSuccess: false)
                    print(error)
                    return
                }
                
                do {
                    if let responseDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                        print("success == \(responseDictionary)")
                        successHandler(response: responseDictionary, isSuccess: true)
                        
                    }
                } catch {
                    print(error)
                    
                    let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("responseString = \(responseString)")
                    successHandler(response: NSDictionary(), isSuccess: false)
                }
            }
            
            task.resume()
            
        }else{
            successHandler(response: NSDictionary(), isSuccess: false)
        }
    }
    
    func RequestForPostAndFile(strUrl:String,postData:NSDictionary,filePathKey:String,filePath:String,successHandler:(response:
        NSDictionary,isSuccess:Bool)-> Void ){
        
        if SharedClass.isReachable {
            
            parmeters = postData
            
            let boundary = generateBoundaryString()
            
            let url = NSURL(string: strUrl)!
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.HTTPBody   = createBodyWithParametersAndFile(postData, filePathKey: filePathKey, paths: filePath,boundary: boundary)
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                if error != nil {
                    // handle error here
                    successHandler(response: NSDictionary(), isSuccess: false)
                    print(error)
                    return
                }
                
                do {
                    if let responseDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                        print("success == \(responseDictionary)")
                        successHandler(response: responseDictionary, isSuccess: true)
                        
                    }
                } catch {
                    print(error)
                    
                    let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("responseString = \(responseString)")
                    successHandler(response: NSDictionary(), isSuccess: false)
                }
            }
            
            task.resume()
            
        }else{
            
            successHandler(response: NSDictionary(), isSuccess: false)
        }
    }
    
    func RequestForPost(url:String, postData:NSDictionary, successHandler:(response:
        NSDictionary,isSuccess:Bool)-> Void ) {
        
        if SharedClass.isReachable {
            parmeters = postData
            
            let request = createRequest(postData,strURL: url)
            
            let session = NSURLSession.sharedSession()
            
            session.configuration.timeoutIntervalForRequest = 30.0
            session.configuration.timeoutIntervalForResource = 60.0
            
            let task = session.dataTaskWithRequest(request) { data, response, error in
                
                if error != nil {
                    
                    //successHandler(response: NSDictionary(), isSuccess: false)
                    //print(error)
                    //return
                    //TODO: only for testing
                    let responseDictionary : NSDictionary = [
                        "data": [
                            "ok": true,
                            "userCtx": [
                                "channels": [
                                    "!": 1,
                                    "automint": 3
                                ],
                                "name": "vrl"
                            ],
                            "mint_code": "AU100",
                            "license": [
                                "cloud": [
                                    "starts": "2016-08-01",
                                    "ends": "2016-10-30"
                                ],
                                "license": [
                                    "starts": "2016-08-01",
                                    "ends": "2016-09-30"
                                ]
                            ]
                        ]
                    ]
                    successHandler(response: responseDictionary, isSuccess: true)
                    return
                }
                
                do {
                    
                    if let responseDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                        
                        print("success == \(responseDictionary)")
                        successHandler(response: responseDictionary, isSuccess: true)
                    }
                    
                }catch {
                    
                    print(error)
                    
                    let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("responseString = \(responseString)")
                    successHandler(response: NSDictionary(), isSuccess: false)
                }
            }
            
            task.resume()
            
        }else{
            
            successHandler(response: NSDictionary(), isSuccess: false)
        }
    }
    
    func createRequest (parameter: NSDictionary,strURL:NSString) -> NSURLRequest {
        
        let boundary = generateBoundaryString()
        
        let url = NSURL(string: strURL as String)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody   = createBodyWithParameters(parameter, boundary: boundary)
        
        return request
    }
    
    func createBodyWithParameters(parameters: NSDictionary?, boundary: String) -> NSData {
        
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    func createBodyWithParametersAndFile(parameters: NSDictionary?, filePathKey: String?, paths: String?,boundary: String) -> NSData {
        
        let body = NSMutableData()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        if paths != ""{
            
            let url = NSURL(fileURLWithPath: paths!)
            let filename = url.lastPathComponent
            let data = NSData(contentsOfURL: url)!
            let mimeType = mimeTypeForPath(paths!)
            
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename!)\"\r\n")
            body.appendString("Content-Type: \(mimeType)\r\n\r\n")
            body.appendData(data)
            body.appendString("\r\n")
        }
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func mimeTypeForPath(path: String) -> String {
        
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }
}

extension NSMutableData {
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}
