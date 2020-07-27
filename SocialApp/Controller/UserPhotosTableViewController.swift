//
//  UserPhotosTableViewController.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/6/5.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import UIKit
import Firebase
import YPImagePicker
import SkeletonView

class UserPhotosTableViewController: UITableViewController {
    
    //使用userID取得firebase上的資料
    private let firebaseService = FirebaseService.init(userID: UserDefaults.standard.string(forKey: UserKey.userID.rawValue)!)
    //存放post
    private var postfeed: [Post] = []
    //是否從firebase下載post，只能由定義的檔案中存取
    fileprivate var isLoadingPost = false

    override func viewDidLoad() {
        super.viewDidLoad()
        //下拉式更新
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.black
        refreshControl?.tintColor = UIColor.white
        //#selector是objec功能，所以要在使用此方法的function宣告的地方加上@objc，表示dynamic Objectivie-C runtime
        refreshControl?.addTarget(self, action: #selector(loadRecentPosts), for: UIControl.Event.valueChanged)
        //觀察是否有新上傳的照片
        NotificationCenter.default.addObserver(self, selector: #selector(loadRecentPosts), name: NSNotification.Name(rawValue: "reloadUserPhotoTable"), object: nil)
        loadRecentPosts()
    }
    
    //MARK: - 下載與顯示post
    @objc func loadRecentPosts(){
        tableView.reloadData()
        isLoadingPost = true
        //使用getRecentPosts(start:limit)取得最近10筆posts
        //postfeed.first.timestamp:取得最早的timestamp
        //第一開始取時會因為postfeed沒東西而沒有timestamp，第二次取是使用第一次拿到的timestamp
        firebaseService.getRecentPosts(start: postfeed.first?.timestamp, limit: 10) { (newPosts) in
            if newPosts.count > 0 {
                //加入posts到array的開始處
                self.postfeed.insert(contentsOf: newPosts, at: 0)
            }
            self.isLoadingPost = false
            //檢查下拉式更新是否啟動
            if let refresh = self.refreshControl?.isRefreshing, refresh == true{
                //延遲0.5秒執行
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    //下拉式更新有啟動就用endRefreshing關閉
                    self.refreshControl?.endRefreshing()
                    //將10筆posts傳給displayNewPosts(newPosts)顯示
                    self.displayNewPosts(newPosts: newPosts)
                }
            } else {
                self.displayNewPosts(newPosts: newPosts)
            }
        }
 
    }

    private func displayNewPosts(newPosts posts: [Post]){
        guard posts.count > 0 else {
            return
        }
        var indexPaths: [IndexPath] = []
        //將post插入至table view
        //用beginUpdates與endUpdate更新tableview，在這兩句之間對tableview的insert/delete的操作會集合起來同時更新UI
        self.tableView.beginUpdates()
        for num in 0...(posts.count-1){
            //在特定的section與row產生indexpath
            let indexPath = IndexPath(row: num, section: 0)
            indexPaths.append(indexPath)
        }
        //使用insertRows插入indexpath，插入位置是indexpath宣告的位置，fade:淡出
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
}

//MARK:- UITableViewDataSource方法
extension UserPhotosTableViewController{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId.userPhotosCell.rawValue, for: indexPath) as! PhotoCell
        //將postfeed中的image與name放到cell裡面的photoImageview與nameLabel中
        let currentPost = postfeed[indexPath.row]
        cell.configure(url: currentPost.imageFileURL, grapher: currentPost.user)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postfeed.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //使用 willDisplay cell 實現無線滾動更新post
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //使用者滑到最後兩列時觸發
        //沒正在取得新貼文以及剩下兩則時更新
        guard !isLoadingPost, postfeed.count - indexPath.row == 2 else {
            return
        }
        
        //剩下兩列，開始觸發更新
        isLoadingPost = true
        guard let lastPostTimestamp = postfeed.last?.timestamp else {
            print("沒取得timestamp")
            isLoadingPost = false
            return
        }
        
        firebaseService.getOldPosts(start: lastPostTimestamp, limit: 3) { (newPosts) in
            //加上new post至目前array與view
            var indexPaths:[IndexPath] = []
            self.tableView.beginUpdates()
            for newPost in newPosts {
                self.postfeed.append(newPost)
                let indexPath = IndexPath(row: self.postfeed.count - 1, section: 0)
                indexPaths.append(indexPath)
            }
            self.tableView.insertRows(at: indexPaths, with: .fade)
            self.tableView.endUpdates()
            self.isLoadingPost = false
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 414.0
    }
}

//MARK:- segue
extension UserPhotosTableViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell {
            if let selectedRow = tableView.indexPath(for: cell)?.row{
                if segue.identifier == segueID.userPhotoToSelectedPhotoSegue.rawValue {
                    if let selectedPhotoVC = segue.destination as? SelectedPhotoViewController {
                        selectedPhotoVC.postFile = postfeed[selectedRow]
                    }
                }
            }
        }
    }
}

