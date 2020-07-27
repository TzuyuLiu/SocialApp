//
//  otherName.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/7/20.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation

public enum cellId: String {
    case cell = "Cell"
    case userLikesCell = "userLikesCell"
    case userPhotosCell = "userPhotosCell"
}

public enum controllerID: String{
    case mainView = "MainView"
    case welcomeView = "WelcomeView"
    case userView = "UserView"
}

public enum providerID: String {
    case facebook = "facebook.com"
    case google = "google.com"
    case line = "line"
    case password = "password"
}

public enum segueID: String {
    case mainToSelectedPhotoSegue
    case userLikeToSelectedPhotoSegue
    case userPhotoToSelectedPhotoSegue
}

