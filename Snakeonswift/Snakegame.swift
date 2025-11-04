import SwiftUI

@main
struct SnakeGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var game = SnakeGame()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    HStack {
                        Text("Score: \(game.score)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        if game.isGameOver {
                            Text("GAME OVER")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    GameBoard(game: game, screenSize: geometry.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if game.isGameOver {
                        Button(action: {
                            game.resetGame()
                        }) {
                            Text("Restart")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 50)
                                .padding(.vertical, 15)
                                .background(Color.green)
                                .cornerRadius(15)
                        }
                        .padding(.bottom, 20)
                    } else {
                        ControlPad(game: game)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct GameBoard: View {
    @ObservedObject var game: SnakeGame
    let screenSize: CGSize

    var body: some View {
        let gridSize = min(screenSize.width * 0.85, screenSize.height * 0.55)
        let cellSize = gridSize / CGFloat(game.gridSize)

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: gridSize, height: gridSize)
                .border(Color.green, width: 3)

            ForEach(game.snake.indices, id: \.self) { index in
                let position = game.snake[index]
                Rectangle()
                    .fill(index == 0 ? Color.green : Color.green.opacity(0.7))
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .offset(
                        x: CGFloat(position.x) * cellSize + 1,
                        y: CGFloat(position.y) * cellSize + 1
                    )
            }

            Circle()
                .fill(Color.red)
                .frame(width: cellSize - 4, height: cellSize - 4)
                .offset(
                    x: CGFloat(game.food.x) * cellSize + 2,
                    y: CGFloat(game.food.y) * cellSize + 2
                )
        }
        .frame(width: gridSize, height: gridSize)
    }
}

struct ControlPad: View {
    @ObservedObject var game: SnakeGame

    var body: some View {
        VStack(spacing: 15) {
            Button(action: { game.changeDirection(.up) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            HStack(spacing: 80) {
                Button(action: { game.changeDirection(.left) }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                Button(action: { game.changeDirection(.right) }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
            }

            Button(action: { game.changeDirection(.down) }) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
        }
    }
}

struct Position: Equatable {
    var x: Int
    var y: Int
}

enum Direction {
    case up, down, left, right
}

class SnakeGame: ObservableObject {
    @Published var snake: [Position] = []
    @Published var food: Position = Position(x: 0, y: 0)
    @Published var direction: Direction = .right
    @Published var isGameOver = false
    @Published var score = 0

    let gridSize = 20
    private var timer: Timer?
    private var nextDirection: Direction = .right

    init() {
        resetGame()
    }

    func resetGame() {
        snake = [
            Position(x: 10, y: 10),
            Position(x: 9, y: 10),
            Position(x: 8, y: 10)
        ]
        direction = .right
        nextDirection = .right
        isGameOver = false
        score = 0
        spawnFood()
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.update()
            }
        }
    }

    func changeDirection(_ newDirection: Direction) {
        switch (direction, newDirection) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            nextDirection = newDirection
        }
    }

    func update() {
        guard !isGameOver else { return }

        direction = nextDirection

        var newHead = snake[0]

        switch direction {
        case .up:
            newHead.y -= 1
        case .down:
            newHead.y += 1
        case .left:
            newHead.x -= 1
        case .right:
            newHead.x += 1
        }

        if newHead.x < 0 || newHead.x >= gridSize || newHead.y < 0 || newHead.y >= gridSize {
            gameOver()
            return
        }

        if snake.contains(newHead) {
            gameOver()
            return
        }

        snake.insert(newHead, at: 0)

        if newHead == food {
            score += 10
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    func spawnFood() {
        var newFood: Position
        repeat {
            newFood = Position(
                x: Int.random(in: 0..<gridSize),
                y: Int.random(in: 0..<gridSize)
            )
        } while snake.contains(newFood)
        food = newFood
    }

    func gameOver() {
        isGameOver = true
        timer?.invalidate()
    }
}