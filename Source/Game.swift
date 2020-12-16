import UIKit

let NUM_SPOTS = 52
let EMPTY = -1

// MARK:-

struct BoardData {
    var position = CGPoint()
    var index = Int()
    var isAtHome = Bool()
}

struct GameData {
    var board = Array(repeating:BoardData(), count: NUM_SPOTS)
    var shuffleCount = Int()
    
    mutating func reset() { shuffleCount = -1 } // -1 = offset the +1 in shuffle()
}

var gd = GameData()

// MARK:-

class Game {
    var finishedSession:Bool = true
    var score = Int()
    
    let DEAL_DELAY:TimeInterval = 0.01
    var dealDelay:TimeInterval = 0
    
    init() {
        cards.setNumberOfDecks(0)
        
        for index in 0 ..< NUM_SPOTS {
            gd.board[index].position.x = 20 + CGFloat(rank(index)) * cardXpos
            gd.board[index].position.y = 20 + CGFloat(suit(index)) * cardYpos
        }
    }
    
    func rank(_ index:Int) -> Int { return index % 13 }
    func suit(_ index:Int) -> Int { return index / 13 }
    func isFirstColumn(_ index:Int) -> Bool { return rank(index) == 0 }
    func isEmptyPosition(_ index:Int) -> Bool { return gd.board[index].index == EMPTY }
    
    // MARK:-
    
    func moveCard(_ index:Int, _ delay:TimeInterval, _ setDoneFlag:Bool = false) {
        if setDoneFlag { self.finishedSession = true }
        
        if !isEmptyPosition(index) {
            UIView.animate(withDuration: 0.1, delay: delay, options: .curveLinear, animations: {
                cards.setPosition(gd.board[index].index, gd.board[index].position)
            }, completion: { (complete: Bool) in } )
        }
    }
    
    func newGame() {
        if !finishedSession { return } // must wait until previous session is finished
        finishedSession = false
        
        gd.reset()
        
        // move All Cards To deal pile
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
            for i in 0 ..< NUM_CARDS {
                cards.setPosition(i, dealPosition)
                cards.setZ(i, i)
            }
        }, completion: { (complete: Bool) in
            // move All Cards To board positions (except Aces)
            for i in 0 ..< NUM_SPOTS {
                gd.board[i].index = (self.rank(i) == 0) ? EMPTY : i }

            self.shuffleCards()
        }
        )
    }
    
    // MARK:-
    
    func updateIsAtHomeMarkers() {
        var targetSuit = Int()
        var isPartOfGroup = Bool()
        
        for i in 0 ..< NUM_SPOTS { gd.board[i].isAtHome = false }
        
        for i in 0 ..< NUM_SPOTS {
            if isFirstColumn(i) {   // must be a '2'
                isPartOfGroup = false
                if isEmptyPosition(i) { continue }

                let card = gd.board[i].index
                
                if rank(card) == 1 { // a '2'
                    gd.board[i].isAtHome = true
                    isPartOfGroup = true
                    targetSuit = suit(card)
                    score += 1
                }
            }
            else {
                if !isPartOfGroup { continue }
                if isEmptyPosition(i) {
                    isPartOfGroup = false
                    continue
                }

                let card = gd.board[i].index
                
                // must be same suit and 1 higher than card to the left
                if (rank(card) != rank(i)+1) || (suit(card) != targetSuit) {
                    isPartOfGroup = false
                }
                else {
                    gd.board[i].isAtHome = true
                    score += 1
                }
            }
        }
    }
    
    func shuffleCards() {
        updateIsAtHomeMarkers()
        
        // shuffle cards not at home
        for _ in 0 ..< 1000 {
            let i1 = Int.random(in: 0 ..< NUM_SPOTS)
            let i2 = Int.random(in: 0 ..< NUM_SPOTS)
            
            if !gd.board[i1].isAtHome && !gd.board[i2].isAtHome {
                let t = gd.board[i1].index
                gd.board[i1].index = gd.board[i2].index
                gd.board[i2].index = t
            }
        }
        
        dealDelay = 0
        for i in 0 ..< NUM_SPOTS {
            self.moveCard(i,self.dealDelay, i == NUM_SPOTS-1)
            self.dealDelay += self.DEAL_DELAY
        }
        
        updateScore()
        gd.shuffleCount += 1
        vc.updateShuffleButton()
    }
    
    // MARK:-
    
    func updateScore() {
        updateIsAtHomeMarkers()
        
        score = 0
        for i in 0 ..< NUM_SPOTS { if gd.board[i].isAtHome { score += 1 }}
        
        vc.updateScore()
    }
    
    // MARK:-
    
    func determineBoardIndex(_ pt:CGPoint) -> Int {
        let yMargin = CGFloat(50)
        var rect = CGRect(x:0, y:0, width:cardXS, height:cardYS + yMargin * 2)
        
        for boardIndex in 0 ..< NUM_SPOTS {
            rect.origin = gd.board[boardIndex].position
            rect.origin.y -= yMargin
            if rect.contains(pt) { return boardIndex }
        }
        
        return EMPTY
    }

    // MARK:- tap
    
    func tap(_ pt:CGPoint) {
        func animateMove(_ newBoardIndex:Int, _ oldBoardIndex:Int) {
            gd.board[newBoardIndex].index = gd.board[oldBoardIndex].index
            gd.board[oldBoardIndex].index = EMPTY

            let newPosition = gd.board[newBoardIndex].position
            let oldPosition = gd.board[oldBoardIndex].position
            let cardIndex = gd.board[newBoardIndex].index
            cards.setPosition(cardIndex, newPosition)
            cards.setDeltaPosition(cardIndex, oldPosition.x - newPosition.x, oldPosition.y - newPosition.y)
            cards.goBackHome(cardIndex)
        }

        let boardIndex = determineBoardIndex(pt)
        if boardIndex == EMPTY { return }       // tapped off the board region
        
        if isEmptyPosition(boardIndex) {        // tapped on empty position. move correct card to this position
            if !isFirstColumn(boardIndex) {     // Not 1st column (they must tap on desired '2' to move to 1st column)
                let nIndex = boardIndex-1       // board index to the left of tapped position
                if  isEmptyPosition(nIndex) { return }      // must hold a card
                
                let nRank = rank(gd.board[nIndex].index)    // rank and suit of the neighboring card
                let nSuit = suit(gd.board[nIndex].index)
                let target = nSuit * 13 + nRank + 1         // index of card to fill the tapped empty position
                
                // find card
                for oldBoardIndex in 0 ..< NUM_SPOTS {
                    if gd.board[oldBoardIndex].index == target {
                        animateMove(boardIndex,oldBoardIndex)
                        break
                    }
                }
            }
            
            updateScore()
            return
        }
        
        // tapped on a card. move it to correct empty position
        let nRank = rank(gd.board[boardIndex].index)    // rank and suit of the tapped card
        let nSuit = suit(gd.board[boardIndex].index)
        let target = nSuit * 13 + nRank - 1             // look for an empty spot with this card to the left
        
        // find empty spot
        for newBoardIndex in 0 ..< NUM_SPOTS {
            if !isEmptyPosition(newBoardIndex) { continue }
            
            if isFirstColumn(newBoardIndex) {  // empty spot is 1st column. can only hold a '2'
                if nRank == 1 {
                    animateMove(newBoardIndex,boardIndex)
                    break
                }
            }
            else {
                if gd.board[newBoardIndex-1].index == target {
                    animateMove(newBoardIndex,boardIndex)
                    break
                }
            }
        }
        
        updateScore()
    }
}
