//
//  GameScene.swift
//  HWS_Project_26
//
//  Created by Cory Tepper on 2/1/21.
//

import CoreMotion
import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case teleport = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
   //MARK: - Properties
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var isTeleporting = false
    
    var motionManager: CMMotionManager?
    var acceleration: Double = 50.0
    var isGameOver = false
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var currentLevel = 1
    var maxLevel = 3
    var levelNodes = [SKSpriteNode]()
    
    // MARK: - View Management
    override func didMove(to view: SKView) {
        
        createBackground()
        createScoreLabel()
       
        loadLevel()
        createPlayer()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.stopAccelerometerUpdates()
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        
        #endif
    }
    
    // MARK: - Game Creation Methods
    func loadLevel() {
        guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else {
            fatalError("Could not find\(currentLevel),txt in the app bundle")
        }
       
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load \(currentLevel).txt from the app bundle")
        }
    
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                    loadWall(at: position)
                } else if letter == "v" {
                    loadVortex(at: position)
                } else if letter == "s" {
                    loadStar(at: position)
                } else if letter == "f" {
                    loadFinishPoint(at: position)
                } else if letter == " " {
                    //this is an empty space - do nothing
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        
        addChild(player)
    }
    
    func createBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
    }
    
    func createScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
    

    func loadWall(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
    
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
        }
    
    func loadVortex(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
    
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
    
        addChild(node)
        }
    
    func loadStar(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
    
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.position = position
        addChild(node)
        }
    
    func loadFinishPoint(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
    
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.position = position
        addChild(node)
        levelNodes.append(node)
    }
    
    func loadTeleport(at posistion: CGPoint, isDeparture: Bool) {
        let node = createNode(called: "teleport", at: position)
        
        if isDeparture {
            node.name = "departure"
        } else {
            node.name = "arrival"
        }
        
        let shrinkDown = SKAction.scale(to: 0.75, duration: 0.25)
        let expand = SKAction.scale(to: 1, duration: 0.25)
        let sequence = SKAction.sequence([shrinkDown, expand])
        node.run(SKAction.repeatForever(sequence))
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
        levelNodes.append(node)
    }
    
    func createNode(called nodeName: String, at position: CGPoint) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: nodeName)
        node.name = nodeName
        node.position = position
            
        return node
    }
    
    //MARK: - Touch Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
        }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }

    //MARK: - Game Logic and Contact Methods
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }

        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
        
    }
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])

            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
                }
            } else if node.name == "star" {
                node.removeFromParent()
                score += 1
            } else if node.name == "finish" {
                player.removeFromParent()
                
                levelNodes.forEach { $0.removeFromParent() }
                levelNodes.removeAll()
                
                if currentLevel == maxLevel {
                    currentLevel = 1
                } else {
                    currentLevel += 1
                }
                
                loadLevel()
                createPlayer()
            } else if node.name == "departure" {
                guard !isTeleporting else { return }
                
                if let teleport = self.childNode(withName: "arrival") {
                    isTeleporting = true
                    player.physicsBody?.isDynamic = false
                    
                    let move = SKAction.move(to: node.position, duration: 0.25)
                    let scaleDown = SKAction.scale(to: 0.001, duration: 0.25)
                    let teleportTo = SKAction.move(to: teleport.position, duration: 0.01)
                    let scaleUp = SKAction.scale(to: 1, duration: 0.25)
                    let restoreDynamic = SKAction.run { [weak self] in self?.player.physicsBody?.isDynamic = true
                    }
                    
                    let sequence = SKAction.sequence([move,scaleDown, teleportTo, scaleUp, restoreDynamic])
                    player.run(sequence)
                    
                    teleport.name = "departure"
                    node.name = "arrival"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in self?.isTeleporting = false
                        
                    }
                } else {
                    return
                }
            }
        }
        
    }

    
    

