//
//  CommentsRepository.swift
//  LocaNotes
//
//  Created by Anthony C on 4/14/21.
//

import Foundation

public class CommentsRepository {
    let sqliteDatabaseService: SQLiteDatabaseService
    let restService: RESTService
    
    init() {
//        self.sqliteDatabaseService = SQLiteDatabaseService()
        self.sqliteDatabaseService = SQLiteDatabaseService.shared
        self.restService = RESTService()
    }
    
    func queryCommentsFromServerBy(userId: String, completion: RESTService.RestResponseReturnBlock<[MongoCommentElement]>) {
        restService.queryCommentsFromServerBy(userId: userId, completion: completion)
    }
    
    func insertComment(serverId: String, noteId: Int32, noteServerId: String, userId: Int32, userServerId: String, body: String, timeCommented: Int32) throws {
        try sqliteDatabaseService.insertComment(serverId: serverId, noteId: noteId, noteServerId: noteServerId, userId: userId, userServerId: userServerId, body: body, timeCommented: timeCommented)
    }
    
    func queryLocalCommentBy(serverId: String) throws -> Comment? {
        try sqliteDatabaseService.queryLocalCommentBy(serverId: serverId)
    }
}
