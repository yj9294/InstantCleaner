//
//  ContactCommand.swift
//  InstantCleaner
//
//  Created by yangjian on 2022/8/3.
//

import Foundation
import Contacts

struct ContactLoadCommand: Command {
    func execute(in store: Store) {
        /// 清空联系人
        store.dispatch(.contactStore([]))
        
        /// 获取Fetch,并且指定要获取联系人中的什么属性
        let keys = [CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactThumbnailImageDataKey]
        
        /// 创建请求对象
        /// 需要传入一个(keysToFetch: [CNKeyDescriptor]) 包含CNKeyDescriptor类型的数组
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        let contact = store.state.contactStore
        var contactArray:[ContactItem] = []
        //遍历所有联系人
        do {
            try contact.enumerateContacts(with: request, usingBlock: {
                (contact : CNContact, stop : UnsafeMutablePointer<ObjCBool>) -> Void in
                
                let imageData = contact.thumbnailImageData
                
                //获取姓名
                let lastName = contact.familyName
                let firstName = contact.givenName
                debugPrint("[contact] 姓名：\(lastName)\(firstName)")
                
                //获取电话号码
                debugPrint("[contact] 电话：")
                var phoneNumber = ""
                if let phone = contact.phoneNumbers.first {
                    //获得标签名（转为能看得懂的本地标签名，比如work、home）
                    var label = "unknown label."
                    if let phoneLabel = phone.label {
                        label = CNLabeledValue<NSString>.localizedString(forLabel: phoneLabel)
                    }
                    
                    //获取号码
                    let value = phone.value.stringValue
                    debugPrint("[contact] \t\(label)：\(value)")
                    phoneNumber = value
                }
                
                let model = ContactItem(name: "\(lastName)\(firstName)", number: phoneNumber, imageData: imageData, contact: contact)
                contactArray.append(model)
            })
        } catch {
            print(error)
        }
                
        /// 更新联系人
        store.dispatch(.contactStore(contactArray))
        
        store.dispatch(.contactFresh)
    }
}

struct ContactFreshCommand: Command {
    func execute(in store: Store) {
        let contactArray = store.state.contact.contacts
        let duplicateNumDict = Dictionary(grouping: contactArray, by: { $0.number })
        let duplicateNameDict = Dictionary(grouping: contactArray, by: { $0.name })
        
        var duplicateName: [[ContactItem]] = []
        var duplicateNumber: [[ContactItem]] = []
        var noName: [[ContactItem]] = []
        var noNumber: [[ContactItem]] = []
        
        for item in duplicateNameDict {
            if item.key == "" {
                noName = [item.value]
            } else if item.value.count > 1 {
                duplicateName.append(item.value)
            }
        }
        
        for item in duplicateNumDict {
            if item.key == "" {
                noNumber = [item.value]
            } else if item.value.count > 1  {
                duplicateNumber.append(item.value)
            }
        }
        
        duplicateNumber.sort {
            ($0.first?.number ?? "") > ($1.first?.number ?? "")
        }
        
        duplicateName.sort{
            ($0.first?.name ?? "") > ($1.first?.name ?? "")
        }
        
        store.dispatch(.contactNoName(noName))
        store.dispatch(.contactNoNumber(noNumber))
        store.dispatch(.contactDuplicateName(duplicateName))
        store.dispatch(.contactDuplicateNumber(duplicateNumber))
    }
}

struct ContactSelectCommand: Command {
    let item: ContactItem
    init(_ item: ContactItem) {
        self.item = item
    }
    func execute(in store: Store) {
        item.isSelected = !item.isSelected
        let contacts: [ContactItem] = store.state.contact.contacts.map({
            if $0.id == item.id {
                return ContactItem(name: $0.name, number: $0.number, imageData: $0.imageData, contact: $0.contact, isSelected: item.isSelected)
            }
            return $0
        })
        /// 更新联系人
        store.dispatch(.contactStore(contacts))
        store.dispatch(.contactFresh)
    }
}

struct ContactDeleteCommand: Command {
    func execute(in store: Store) {
        let selectContactArray: [CNContact?] = store.state.contact.contacts.filter {
            $0.isSelected == true
        }.map {
            $0.contact
        }
        
        let group = DispatchGroup()
        selectContactArray.forEach { contact in
            // 删除联系人请求
            if let contact = contact?.mutableCopy() as? CNMutableContact {
                group.enter()
                let request = CNSaveRequest()
                request.delete(contact)
                do {
                    //执行操作
                    try store.state.contactStore.execute(request)
                    debugPrint("[contact] delete contact:\(contact.givenName) successfully.")
                    group.leave()
                } catch let err {
                    debugPrint("[contact] error \(err)")
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            store.dispatch(.rootAlert(selectContactArray.count > 1 ? "\(selectContactArray.count) contacts cleaned up successfully" : "1 contact cleaned up successfully"))
        }
        
        let sourceContacts = store.state.contact.contacts.filter {
            $0.isSelected == false
        }
        store.dispatch(.contactStore(sourceContacts))
        store.dispatch(.contactFresh)
    }
}

struct ContactAllSelectCommand: Command {
    let point: AppState.Contact.Point
    init(_ point: AppState.Contact.Point) {
        self.point = point
    }
    func execute(in store: Store) {
        var array: [ContactItem] = []
        switch point {
        case .duplicateName:
            array = store.state.contact.duplicationName.flatMap({
                $0
            })
        case .duplicateNumber:
            array = store.state.contact.duplicationNumber.flatMap({
                $0
            })
        case .noName:
            array = store.state.contact.noName.flatMap({
                $0
            })
        case .noNumber:
            array = store.state.contact.noNumber.flatMap({
                $0
            })
        }
        let contacts: [ContactItem] = store.state.contact.contacts.map({
            return ContactItem(name: $0.name, number: $0.number, imageData: $0.imageData, contact: $0.contact, isSelected: array.contains($0))
        })
        /// 更新联系人
        store.dispatch(.contactStore(contacts))
        store.dispatch(.contactFresh)
        
    }
}

struct ContactCancelSelectCommand: Command {
    func execute(in store: Store) {
        let contacts: [ContactItem] = store.state.contact.contacts.map({
            return ContactItem(name: $0.name, number: $0.number, imageData: $0.imageData, contact: $0.contact, isSelected: false)
        })
        /// 更新联系人
        store.dispatch(.contactStore(contacts))
        store.dispatch(.contactFresh)
    }
}
