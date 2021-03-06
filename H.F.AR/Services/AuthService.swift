//
//  AuthService.swift
//  H.F.AR
//
//  Created by 이주원 on 2018. 4. 7..
//  Copyright © 2018년 Apple. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON

class AuthService {
    static let instance = AuthService()
    
    let defaults = UserDefaults.standard
    
    var isLoggedIn: Bool {
        get {
            return defaults.bool(forKey: LOGGED_IN_KEY)
        } set {
            defaults.set(newValue, forKey: LOGGED_IN_KEY)
        }
    }
    
    var userId: String {
        get {
            return defaults.value(forKey: USER_ID) as! String
        } set {
            defaults.set(newValue, forKey: USER_ID)
        }
    }
    
    func setAndLoadUserInfoById(completion: @escaping CompletionHandler) {
        let body: [String:Any] = [
            "method": GET_USER_INFO,
            "user_id": userId
        ]
        
        // Web Request
        Alamofire.request("\(BASE_URL)\(REQUEST_SUFFIX)", method: .post, parameters: body, encoding: URLEncoding.default, headers: URL_ENCODE_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                var json = JSON(data)
                // Due to the response characteristic
                json = json[0]
                // Store common user information
                let id = json["id"].stringValue
                let email = json["email"].stringValue
                let familyName = json["family_name"].stringValue
                let givenName = json["given_name"].stringValue
                let fullName = json["full_name"].stringValue
                let provider = json["provider"].stringValue
                var profileImageLink = ""
                // Store user information by provider
                if json["provider"].stringValue == "Google" {
                    profileImageLink = json["google_picture_link"].stringValue
                } else if json["provider"].stringValue == "Microsoft" {
                    profileImageLink = "\(MICROSOFT_PROFILE_IMAGE_BASE_REQUEST_URL_PREFIX)\(json["id"])\(MICROSOFT_PROFILE_IMAGE_BASE_REQUEST_URL_SUFFIX)"
                } else {
                    completion(false)
                    return
                }
                // Get profile image
                Alamofire.request(profileImageLink).responseImage(completionHandler: { (response) in
                    if let profileImage = response.result.value {
                        // Setting User Data when there is profile picture
                        UserDataService.instance.setUserData(id: id, email: email, familyName: familyName, givenName: givenName, fullName: fullName, provider: provider, profileImage: profileImage)
                    } else {
                        // Setting User Data when there is NO profile picture
                        UserDataService.instance.setUserData(id: id, email: email, familyName: familyName, givenName: givenName, fullName: fullName, provider: provider)
                    }
                    self.isLoggedIn = true
                    NotificationCenter.default.post(name: NOTIF_USER_DATA_LOADED, object: nil)
                    completion(true)
                })
            }
        }
    }
}
