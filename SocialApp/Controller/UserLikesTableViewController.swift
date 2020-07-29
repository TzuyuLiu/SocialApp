//
//  UserLikesTableViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/5.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit

class UserLikesTableViewController: UITableViewController {
    
    //使用userID取得firebase上的資料
    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    private var likePhotos:[LikePhoto] = []
    fileprivate var isLoadingPhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPhotos()
        NotificationCenter.default.addObserver(self, selector: #selector(loadPhotos), name: NSNotification.Name(rawValue: "refreshLikePhoto"), object: nil)
    }
    
    //MARK:- 下載與顯示photo
    @objc func loadPhotos(){
        likePhotos.removeAll()
        tableView.reloadData()
        isLoadingPhoto = true
    
        firebaseService.getlikePhotos { (Photos) in
            if Photos.count > 0 {
                self.likePhotos.insert(contentsOf: Photos, at: 0)
            }
            self.isLoadingPhoto = false
            self.displayLikePhotos(photos: Photos)
        }
    }
    
    private func displayLikePhotos(photos:[LikePhoto]){
        guard photos.count > 0  else {
            print("沒有photos顯示")
            return
        }
        var indexPaths: [IndexPath] = []
        self.tableView.beginUpdates()
        for num in 0...(photos.count-1){
            let indexPath = IndexPath(row: num, section: 0)
            indexPaths.append(indexPath)
        }
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
}

//MARK:- UITableViewDataSource方法
extension UserLikesTableViewController{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId.userLikesCell.rawValue, for: indexPath) as! PhotoCell
        let currentPhotos = likePhotos[indexPath.row]
        cell.configure(url: currentPhotos.photoURL, grapher: currentPhotos.name)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likePhotos.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //將每個cell調整到與photo一樣比例的尺寸
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = Double(tableView.frame.width) / Double(likePhotos[indexPath.row].width) * Double(likePhotos[indexPath.row].height)
        return CGFloat(cellHeight)
    }
}

//MARK:- segue
extension UserLikesTableViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell {
            if let selectedRow = tableView.indexPath(for: cell)?.row{
                if segue.identifier == segueID.userLikeToSelectedPhotoSegue.rawValue {
                    if let selectedPhotoVC = segue.destination as? SelectedPhotoViewController {
                        selectedPhotoVC.likePhotoFile = likePhotos[selectedRow]
                    }
                }
            }
        }
    }
}
