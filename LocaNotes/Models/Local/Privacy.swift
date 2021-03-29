//
//  Privacy.swift
//  LocaNotes
//
//  Created by Anthony C on 3/24/21.
//

import Foundation

struct Privacy {
    let privacyId: Int32
    let label: NSString
}

extension Privacy: SQLTable {
    
    static var createStatement: String {
        return """
            CREATE TABLE Privacy(
                PrivacyId INTEGER NOT NULL PRIMARY KEY,
                Label TEXT NOT NULL
            );
        """
    }
}