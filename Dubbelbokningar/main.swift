//
//  main.swift
//  Dubbelbokningar
//
//  Created by Erik Aderstedt on 2019-07-18.
//  Copyright © 2019 Aderstedt Software AB. All rights reserved.
//

import Foundation

print(#"""
     ____        _     _          _
    |  _ \ _   _| |__ | |__   ___| |
    | | | | | | | '_ \| '_ \ / _ \ |_____
    | |_| | |_| | |_) | |_) |  __/ |_____|
    |____/ \__,_|_.__/|_.__/ \___|_|
     _           _          _                       ___
    | |__   ___ | | ___ __ (_)_ __   __ _  __ _ _ _|__ \
    | '_ \ / _ \| |/ / '_ \| | '_ \ / _` |/ _` | '__|/ /
    | |_) | (_) |   <| | | | | | | | (_| | (_| | |  |_|
    |_.__/ \___/|_|\_\_| |_|_|_| |_|\__, |\__,_|_|  (_)

                          © Erik Aderstedt 2019
                            0768 674 640 / erik@aderstedt.se
"""#)
print("""
Använd så här:
Kopiera tabellen med bokningar från Safari.
Kör sedan: pbpaste | cut -f4 | egrep -v Plats | sort | uniq -c | ./Dubbelbokningar
Med lite lätt modifikation av ovanstående kommandorad går det att köra på rå databasoutput också.

""")


enum MyError: Error {
    case runtimeError(String)
}

struct Deltilldelning: Sequence {
    let från: Int
    let till: Int
    let område: String?
    
    init(_ beskrivning: String) throws {
        let omfattning: String
        if beskrivning.lengthOfBytes(using: .ascii) == 0 {
            throw MyError.runtimeError(beskrivning)
        }
        if Int(String(beskrivning.prefix(1))) == nil {
            område = String(beskrivning.prefix(1))
            omfattning = String(beskrivning.suffix(from: beskrivning.index(after: beskrivning.startIndex)))
        } else {
            område = nil
            omfattning = beskrivning
        }
        let siffror = omfattning.components(separatedBy: "-").compactMap({ Int($0) })
        guard let i = siffror.first else { throw MyError.runtimeError(beskrivning) }
        
        från = i
        till = (siffror.count < 2) ? i : siffror[1]
    }
    
    func makeIterator() -> DeltilldelningIterator {
        return DeltilldelningIterator(self)
    }
    
    var antal: Int {
        return till - från + 1
    }
}

struct DeltilldelningIterator: IteratorProtocol {
    
    var nuvarande: Int?
    let deltilldelning: Deltilldelning
    
    init(_ d: Deltilldelning) {
        nuvarande = d.från
        deltilldelning = d
    }
    
    mutating func next() -> Int? {
        let nästa: Int?
        if let nuvarande = nuvarande, nuvarande + 1 <= deltilldelning.till {
            nästa = nuvarande + 1
        } else {
            nästa = nil
        }
        let returnera = nuvarande
        nuvarande = nästa
        return returnera
    }
}

var fördeladePlatser = 0
var platser = [String:[Int]]()

while true {
    guard let rad = readLine(strippingNewline: true) else { break }
    let delar = rad.components(separatedBy: .whitespaces).filter({ $0 != "" })
    if delar.count < 2 { continue }
    let antal = Int(delar[0]) ?? 0
    let beskrivning = delar[1]
    let deltilldelningar = beskrivning.components(separatedBy: ",").compactMap { try? Deltilldelning($0) }
    let totalt = deltilldelningar.map({ $0.antal }).reduce(0) { $0 + $1 }
    fördeladePlatser = fördeladePlatser + totalt
    
    if antal != totalt {
        print("Extra plats:", antal, beskrivning, totalt)
    }
    
    var nuvarandeOmråde: String?
    for dt in deltilldelningar {
        if let nyttOmråde = dt.område {
            nuvarandeOmråde = nyttOmråde
        }
        
        guard let område = nuvarandeOmråde else {
            // Första intervallet på raden saknar områdesbokstav.
            fatalError(beskrivning)
        }
        
        var tilldeladePlatserInomOmråde: [Int] = platser[område] ?? []
        for plats in dt {
            if tilldeladePlatserInomOmråde.contains(plats) {
                print("Konflikt:", område, plats)
            } else {
                tilldeladePlatserInomOmråde.append(plats)
            }
        }
        platser[område] = tilldeladePlatserInomOmråde
    }

}

print("---")

let områdesbokstäver = platser.keys.sorted()
for område in områdesbokstäver {
    let tilldeladePlatser = platser[område] ?? []
    print("Område",område,"har", tilldeladePlatser.count, "tilldelade platser.")
}
