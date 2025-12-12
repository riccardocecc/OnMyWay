//
//  Pair.swift
//  OnMyWay
//
//  Created by Riccardo Ceccarani on 12/12/25.
//

import Foundation
import FirebaseFirestore

// La relazione permanente tra due utenti
struct Pair: Identifiable, Codable {
    @DocumentID var id: String?
    
    let user1Id: String
    let user2Id: String
    let createdAt: Date
}
