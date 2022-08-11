//
//  SpeedCommand.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/5.
//

import Foundation

struct SpeedRequestIPCommand: Command {
    func execute(in store: Store) {
        
        let token = SubscriptionToken()
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "http://pv.sohu.com/cityjson?ie=utf-8")!)
//            .map{ $0.data }
//            .decode(type: IpModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
            .sink { complete in
                if case .failure(_) = complete {
                    store.dispatch(.speedIP(""))
                    store.dispatch(.speedCountry(""))
                }
                token.unseal()
            } receiveValue: { data in
                var string = String(data: data.data, encoding: .utf8)
                string = string?.replacingOccurrences(of: "var returnCitySN = ", with: "")
                string?.removeLast()
                if let stringData = string?.data(using: .utf8) , let json = try?JSONDecoder().decode(IpModel.self, from: stringData){
                    debugPrint(json)
                    store.dispatch(.speedIP(json.cip ?? ""))
                    store.dispatch(.speedCountry(json.cname ?? ""))
                } else {
                    store.dispatch(.speedIP(""))
                    store.dispatch(.speedCountry(""))
                }
            }.seal(in: token)
    }
    
    struct IpModel: Codable {
        var cip: String?
        var cid: String?
        var cname: String?
    }
}

struct SpeedStartTestCommand: Command {
    func execute(in store: Store) {
        store.state.animation.testingModel.animationView.play()
        store.state.speed.monitorFlowModel.startMonitor()
        
        let token = SubscriptionToken()
        let timerToken = SubscriptionToken()
        let maxToken = SubscriptionToken()
        var isDownload = false
        var isPing = false
        
        var uploadArray: [UInt64] = []
        var downloadArray: [UInt64] = []
        
        store.dispatch(.speedPing("0"))
        
        Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            if store.state.speed.status == .normal {
                timerToken.unseal()
                token.unseal()
                maxToken.unseal()
                return
            }
            if isDownload, isPing {
                timerToken.unseal()
                store.dispatch(.speedUpload(uploadArray.max() ?? 0))
                store.dispatch(.speedDownload(downloadArray.max() ?? 0))
                store.dispatch(.speedStatus(.tested))
                store.dispatch(.speedStopTest)
                
                
                // 广告
                store.dispatch(.adLoad(.interstitial))
                let loadedAd = store.state.ad.isLoaded(.interstitial)
                if loadedAd {
                    store.dispatch(.adDisapear(.native))
                }
                store.dispatch(.adShow(.interstitial, { _ in
                    if loadedAd {
                        store.dispatch(.adLoad(.native))
                    }
                    store.dispatch(.rootAlert("Speed Test Done"))
                }))
                return
            }
            let upload = store.state.speed.monitorFlowModel.send
            let download = store.state.speed.monitorFlowModel.receive
            uploadArray.append(upload)
            downloadArray.append(download)
            store.dispatch(.speedUpload(upload))
            store.dispatch(.speedDownload(download))
        }.seal(in: timerToken)
        
        Timer.publish(every: 20, on: .main, in: .common).autoconnect().sink { _ in
            timerToken.unseal()
            maxToken.unseal()
            token.unseal()
            
            store.dispatch(.speedUpload(uploadArray.max() ?? 0))
            store.dispatch(.speedDownload(downloadArray.max() ?? 0))
            
            // 超时广告
            store.dispatch(.adLoad(.interstitial))
            let loadedAd = store.state.ad.isLoaded(.interstitial)
            if loadedAd {
                store.dispatch(.adDisapear(.native))
            }
            store.dispatch(.adShow(.interstitial, { _ in
                if loadedAd {
                    store.dispatch(.adLoad(.native))
                }
                store.dispatch(.rootAlert("Speed Test Done"))
            }))
            isDownload = true
            isPing = true
        }.seal(in: maxToken)


        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://images.apple.com/v/imac-with-retina/a/images/overview/5k_image.jpg")!).sink { complete in
                    token.unseal()
                    if case .failure(_) = complete {
                        uploadArray.removeAll()
                        downloadArray.removeAll()
                    }
                    if !isDownload {
                        isDownload = true
                    }
                } receiveValue: { data in
                }.seal(in: token)
        }
        
        store.state.speed.test.ping(host: SpeedTestHost(url: URL(string: "https://api.infoip.io/")!, name: "", country: "", cc: "", host: "", sponsor: ""), timeout: 20) { result in
            switch result {
            case .value(let ping):
                store.dispatch(.speedPing("\(ping)"))
            default:
                store.dispatch(.speedPing("0"))
            }
            if !isPing {
                isPing = true
            }
        }
    }
}

struct SpeedStopTestCommand: Command {
    func execute(in store: Store) {
        store.state.animation.testingModel.animationView.stop()
        store.state.speed.monitorFlowModel.stopMonitor()
    }
}
