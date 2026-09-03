const canvas = document.querySelector("#game");
const context = canvas.getContext("2d");
const scoreElement = document.querySelector("#score");
const statusElement = document.querySelector("#game-status");
const startButton = document.querySelector("#start-button");
const scoresElement = document.querySelector("#scores");
const refreshButton = document.querySelector("#refresh-scores");
const databaseLight = document.querySelector("#db-light");
const databaseStatus = document.querySelector("#db-status");

const cellSize = 24;
const cells = canvas.width / cellSize;
const colors = {
  grid: "rgba(155, 234, 112, 0.055)",
  snake: "#9bea70",
  head: "#d7ffc2",
  food: "#ffb84d",
};

let snake;
let food;
let direction;
let queuedDirection;
let score;
let timer;
let running = false;
let submitted = false;

function randomCell() {
  return {
    x: Math.floor(Math.random() * cells),
    y: Math.floor(Math.random() * cells),
  };
}

function placeFood() {
  do {
    food = randomCell();
  } while (snake.some((segment) => segment.x === food.x && segment.y === food.y));
}

function resetGame(initialDirection = { x: 1, y: 0 }) {
  const center = { x: 10, y: 10 };
  snake = [
    center,
    { x: center.x - initialDirection.x, y: center.y - initialDirection.y },
    { x: center.x - initialDirection.x * 2, y: center.y - initialDirection.y * 2 },
  ];
  direction = initialDirection;
  queuedDirection = direction;
  score = 0;
  submitted = false;
  placeFood();
  updateScore();
  draw();
}

function updateScore() {
  scoreElement.textContent = String(score).padStart(4, "0");
}

function drawGrid() {
  context.strokeStyle = colors.grid;
  context.lineWidth = 1;
  for (let index = 0; index <= cells; index += 1) {
    const offset = index * cellSize + 0.5;
    context.beginPath();
    context.moveTo(offset, 0);
    context.lineTo(offset, canvas.height);
    context.stroke();
    context.beginPath();
    context.moveTo(0, offset);
    context.lineTo(canvas.width, offset);
    context.stroke();
  }
}

function drawCell(cell, color, inset = 3) {
  context.fillStyle = color;
  context.fillRect(
    cell.x * cellSize + inset,
    cell.y * cellSize + inset,
    cellSize - inset * 2,
    cellSize - inset * 2,
  );
}

function draw() {
  context.clearRect(0, 0, canvas.width, canvas.height);
  drawGrid();
  drawCell(food, colors.food, 6);
  snake.forEach((segment, index) => drawCell(segment, index === 0 ? colors.head : colors.snake));
}

function samePosition(first, second) {
  return first.x === second.x && first.y === second.y;
}

function tick() {
  direction = queuedDirection;
  const head = {
    x: snake[0].x + direction.x,
    y: snake[0].y + direction.y,
  };

  const hitWall = head.x < 0 || head.x >= cells || head.y < 0 || head.y >= cells;
  const eating = samePosition(head, food);
  const collisionSegments = eating ? snake : snake.slice(0, -1);
  const hitSelf = collisionSegments.some((segment) => samePosition(segment, head));
  if (hitWall || hitSelf) {
    finishGame();
    return;
  }

  snake.unshift(head);
  if (eating) {
    score += 10;
    updateScore();
    placeFood();
    scheduleTick();
  } else {
    snake.pop();
  }
  draw();
}

function scheduleTick() {
  clearInterval(timer);
  const delay = Math.max(70, 150 - Math.floor(score / 50) * 10);
  timer = setInterval(tick, delay);
}

function setDirection(next) {
  if (!running) {
    startGame(next);
    return;
  }
  if (next.x + direction.x === 0 && next.y + direction.y === 0) return;
  queuedDirection = next;
}

function startGame(initialDirection = { x: 1, y: 0 }) {
  clearInterval(timer);
  resetGame(initialDirection);
  running = true;
  statusElement.textContent = "Signal live";
  startButton.textContent = "RESTART";
  scheduleTick();
}

async function finishGame() {
  clearInterval(timer);
  running = false;
  statusElement.textContent = `Game over · ${score} points`;
  if (!submitted) {
    submitted = true;
    await submitScore(score);
  }
}

async function submitScore(finalScore) {
  try {
    const response = await fetch("/api/scores", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ score: finalScore }),
    });
    if (!response.ok) throw new Error(`Score submission failed with ${response.status}`);
    await loadScores();
  } catch (error) {
    console.error(error);
    statusElement.textContent = `Game over · score link unavailable`;
    setDatabaseState(false);
  }
}

function renderScores(scores) {
  if (scores.length === 0) {
    scoresElement.innerHTML = '<li class="score-message">No scores yet. Open the trail.</li>';
    return;
  }

  scoresElement.replaceChildren(
    ...scores.map((entry) => {
      const item = document.createElement("li");
      const value = document.createElement("span");
      const date = document.createElement("time");
      value.className = "score-value";
      value.textContent = String(entry.score).padStart(4, "0");
      date.className = "score-date";
      date.dateTime = entry.created_at;
      date.textContent = new Date(entry.created_at).toLocaleDateString(undefined, {
        month: "short",
        day: "2-digit",
      });
      item.append(value, date);
      return item;
    }),
  );
}

function setDatabaseState(online) {
  databaseLight.classList.toggle("is-online", online);
  databaseLight.classList.toggle("is-offline", !online);
  databaseStatus.textContent = online ? "Score link online" : "Score link offline";
}

async function loadScores() {
  scoresElement.innerHTML = '<li class="score-message">Reading score trail…</li>';
  try {
    const response = await fetch("/api/scores", { headers: { Accept: "application/json" } });
    if (!response.ok) throw new Error(`Score request failed with ${response.status}`);
    const payload = await response.json();
    renderScores(payload.scores);
    setDatabaseState(true);
  } catch (error) {
    console.error(error);
    scoresElement.innerHTML = '<li class="score-message is-error">Score trail unavailable</li>';
    setDatabaseState(false);
  }
}

const directions = {
  ArrowUp: { x: 0, y: -1 },
  w: { x: 0, y: -1 },
  ArrowDown: { x: 0, y: 1 },
  s: { x: 0, y: 1 },
  ArrowLeft: { x: -1, y: 0 },
  a: { x: -1, y: 0 },
  ArrowRight: { x: 1, y: 0 },
  d: { x: 1, y: 0 },
};

document.addEventListener("keydown", (event) => {
  const next = directions[event.key];
  if (!next) return;
  event.preventDefault();
  setDirection(next);
});

document.querySelectorAll("[data-direction]").forEach((button) => {
  button.addEventListener("click", () => {
    const key = `Arrow${button.dataset.direction[0].toUpperCase()}${button.dataset.direction.slice(1)}`;
    setDirection(directions[key]);
  });
});

startButton.addEventListener("click", startGame);
refreshButton.addEventListener("click", loadScores);

resetGame();
loadScores();
