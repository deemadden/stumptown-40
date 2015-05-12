//
//  User.swift
//  StumptownFortyBus
//
//  Created by Dee Madden on 5/11/15.
//  Copyright (c) 2015 RGA. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {

    @NSManaged var accessToken: String
    @NSManaged var userID: String

}
