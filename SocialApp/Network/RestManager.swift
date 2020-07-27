//
//  RestManager.swift
//  SocialApp
//
//  Created by 劉子瑜 on 2020/5/28.
//  Copyright © 2020 劉子瑜. All rights reserved.
//

import Foundation

class RestManager{
    
    
    var requestHttpHeaders = RestEntity()
    
    var urlQueryParameters = RestEntity()
    
    var httpBodyParameters = RestEntity()
    
    var httpBody: Data?
    
    private func addURLQueryParameters(toURL url: URL) -> URL{
        //確認有URL查詢參數，如果沒有就回傳原本傳入的url
        if urlQueryParameters.totalItems() > 0 {
            //使用URLComponents物件處理URL及其部分，初始物件需要原始URL物件
            //用URLComponents產生url，URLComponents提供一個名為queryItems屬性
            //URLComponents會回傳nil，所以要用guard
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var queryItems = [URLQueryItem]()
            for (key,value) in urlQueryParameters.allValues(){
                //將value使用Percent Encoding來將空白等特殊字元轉換編碼
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                //轉換好的item加到queryItems
                queryItems.append(item)
            }
            //將querItem指派到urlComponents
            urlComponents.queryItems = queryItems
            
            //urlComponents.url能產生出url，取得完整參數url
            //components的url為optional
            guard let updateURL = urlComponents.url else { return url }
            return updateURL
        }
        //沒有URL查詢參數就回傳原本傳入的url
        return url
    }
    
    //設定http message body，若header未被指定或沒回傳資料，方法則回傳nil
    private func getHttpBody() -> Data?{
        guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else {
            print("沒有取得content-Type")
            return nil
        }
        
        //檢查內容型別，依照型別來轉換資料型態
        if contentType.contains("application/json"){
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            //$0:key $1:value，用addingPercentEncoding轉換特殊字元的編碼，用joined串起所有通過map的string
            let bodyString = httpBodyParameters.allValues().map { "\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        } else {
            //其他非兩種型別的直接回傳
            return httpBody
        }
    }
    
    //建立URLRequset，url與httpBody因為makeRequest中self的關係都有可能是nil
    private func prepareRequest(withURL url: URL?,httpBody: Data?, httpMethod: HTTPMethod) -> URLRequest?{
        //若沒辦法建立url，就會回傳ni
        guard let url = url else { return nil }
        var request = URLRequest(url: url)
        //httpMethod需要用string指定
        request.httpMethod = httpMethod.rawValue
        //將http header指派到request
        for (header,value) in requestHttpHeaders.allValues() {
            request.setValue(value, forHTTPHeaderField: header)
        }
        request.httpBody = httpBody
        return request
    }
    
    func makeRequest(toURL url: URL, withHttpMethod httpMethod: HTTPMethod, completion: @escaping(_ result: Results) -> Void) {
        //request因為並非立即的，在請求時應維持能夠繼續使用app，所以需要在背景執行緒里非同步進行
        //QOS(Quality of Service)有四種主要類型以及一種默認類型(為系統自行判斷時間)，userInitiated是代表運行時間只有幾秒鐘或更短，執行緒順位第二
        //使用self讓RestManage變成optional型態，沒使用就不會存在，weak則是在ARC機制中不會讓reference count增加，且經常被宣告為optional type
        //所以若RestManager實例因為某些原因停止存活的話，用weak self確保任何類別屬性與方法的參照不會導致閃退
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            //因為self的關係，原先addURLQueryParameters並不會回傳nil的變成有可能回傳nil
            let targetURL = self?.addURLQueryParameters(toURL: url)
            let httpBody = self?.getHttpBody()
            
            guard let request = self?.prepareRequest(withURL: targetURL, httpBody: httpBody, httpMethod: httpMethod) else {
                //若request是nil，就用使用自定義的錯誤說明
                completion(Results(withError: CustomError.failedToCreateRequest))
                return
            }
            
            //URLSessionConfiguration可以用來設置網路會話的相關配置
            let sessionConfiguration = URLSessionConfiguration.default
            //使用URLSession建立data task
            let session = URLSession(configuration: sessionConfiguration)
            //產生urlsession物件
            let task = session.dataTask(with: request) { (data, response, error) in
                //透過completion裡面的@escaping讓closure以及其參數在function外面繼續使用
                completion(Results(withData: data, response: Response(fromURLResponse: response), error: error))
            }
            //使用resume開始網路請求(上傳或下載資料)
            task.resume()
        }
    }
    
    func getData(fromURL url: URL, completion: @escaping(_ data: Data?) -> Void){
        
        DispatchQueue.global(qos: .userInitiated).async {
        
            //URLSessionConfiguration可以用來設置網路會話的相關配置
            let sessionConfiguration = URLSessionConfiguration.default
            //使用URLSession建立data task
            let session = URLSession(configuration: sessionConfiguration)
            //產生urlsession物件
            let task = session.dataTask(with: url) { (data, response, error) in
                
                guard let data = data else {
                    completion(nil)
                    return
                }
                completion(data)
            }
            
            task.resume()
        }
    }
}

extension RestManager{
    
    struct RestEntity {
        private var values: [String:String] = [:]
        
        //mutating:代表會將更動指定給一個新的實例，並且新的實例會在方法結束後將舊的實例覆蓋掉
        mutating func add(value: String, forKey key: String){
            values[key] = value
        }
        
        func value(forKey key: String) -> String? {
            return values[key]
        }
        
        func allValues() -> [String:String]{
            return values
        }
        //算url查詢參數個數
        func totalItems() -> Int {
            return values.count
        }
    }
    
    struct Response{
        //保留實際的回應物件，不會包含伺服器回傳的資料
        var response: URLResponse?
        var httpStatusCode: Int = 0
        var headers = RestEntity()
        
        //接收一個URLResponse物件保留在response屬性中
        init(fromURLResponse response: URLResponse?){
            guard let response = response else { return }
            self.response = response
            //取得HTTP狀態碼
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            //allHeaderFields：獲取目前所有的header
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields{
                for(key, value) in headerFields {
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
    }
    
    struct Results{
        var data: Data?
        var response: Response?
        //自定義的error型態
        var error: Error?
        
        init(withData data: Data?,response: Response?,error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error) {
            self.error = error
        }
    }
    
    enum CustomError: Error{
        case failedToCreateRequest
    }
}

extension RestManager.CustomError: LocalizedError{
    //採用LocalizedError協定來自定義錯誤
    //LocalizedError:用來描述錯誤及發生原因的localizedescription
    public var localizedDescription: String{
        switch self {
        case .failedToCreateRequest:
            return NSLocalizedString("Unable to create the URLRequest object", comment: "")
        }
    }
}
