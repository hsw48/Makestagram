//
//  Post.swift
//  Makestagram
//
//  Created by Harrison Woodward on 6/27/16.
//  Copyright © 2016 Harrison Woodward. All rights reserved.
//


import Foundation
import Parse
import Bond


class Post : PFObject, PFSubclassing {
    
    var image: Observable<UIImage?> = Observable(nil)
    var likes: Observable<[PFUser]?> = Observable(nil)
    
    
    @NSManaged var user: PFUser?
    @NSManaged var imageFile: PFFile?
    
    var photoUploadTask : UIBackgroundTaskIdentifier?
    
    func uploadPost() {
        if let image = image.value {
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {return}
            guard let imageFile = PFFile(name: "image.jpg",data: imageData) else {return}
            
            user = PFUser.currentUser()
            self.imageFile = imageFile
            
            photoUploadTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
            saveInBackgroundWithBlock() { (success: Bool, error: NSError?) in
                UIApplication.sharedApplication().endBackgroundTask(self.photoUploadTask!)
            }
        }
    }
    
    func fetchLikes() {
        if likes.value != nil {
            return
        }
        ParseHelper.likesForPost(self, completionBlock:{ (likes: [PFObject]?, error: NSError?) -> Void in
            let validLikes = likes?.filter { like in like[ParseHelper.ParseLikeFromUser] != nil }
            self.likes.value = validLikes?.map { like in
                let fromUser = like[ParseHelper.ParseLikeFromUser] as! PFUser
                return fromUser
        
            }
        })
    }
    
    
    
    func doesUserLikePost(user: PFUser) -> Bool {
        if let likes = likes.value {
            return likes.contains(user)
        } else {
            return false
        }
    }
    
    func toggleLikePost(user: PFUser) {
        if (doesUserLikePost(user)) {
            likes.value = likes.value?.filter { $0 != user }
            ParseHelper.unlikePost(user, post: self)
        } else {
            likes.value?.append(user)
            ParseHelper.likePost(user, post: self)
        }
    }
    
    func downloadImage() {
        if image.value == nil {
            imageFile?.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                if let data = data {
                    let image = UIImage(data: data, scale: 1.0)!
                    
                    self.image.value = image
                }
            })
        }
    }
    
    static func parseClassName() -> String {
        return "Post"
    }
    
   
    override init () {
        super.init()
    }
    
    override class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            // inform Parse about this subclass
            self.registerSubclass()
        }
    }
    
}