// README
// 
// CONWAY'S GAME OF LIFE
// An implementation in Processing by Kaylah Facey.
//
// c,C - Mass extinction of all cells. (Clear the grid to all black *and switch to single-step mode*.)
// r,R - Randomize the state of the grid (each cell is black or white with equal probability).
// g,G - Toggle between single-step and continuous update mode.
// space bar - Switch to single-step mode and take one simulation step.
// Hover over a cell to "preview" toggling it. Click to *toggle* it between white and black.


color black = color(0);
color white = color(255);
color lightgrey = color(170);
color darkgrey = color(85);
int side = 100;
int[][] cells = new int[side][side];
int[][] neighbors = new int[side][side];
int size = 9;
boolean continuous = false; // Whether to draw in continuous or single step mode.

void setup() {
  size(900, 900);
}

void draw() {
  background(black);
  for (int x = 0; x < side; x++) {
    for (int y = 0; y < side; y++) {
      // Populate grid.
      if (cells[x][y] == 1) {
        int gridX = cell_to_grid(x);
        int gridY = cell_to_grid(y);
        square(gridX, gridY, size);
      }
    }
  }
  if (continuous) {
    update(); 
  }
  // Show location of mouse cell.
  int cellX = grid_to_cell(mouseX);
  int cellY = grid_to_cell(mouseY);
  int gridX = cell_to_grid(cellX);
  int gridY = cell_to_grid(cellY);
  if (cells[cellX][cellY] == 0) {
    fill(lightgrey);
  } else {
    fill(darkgrey);
  }
  square(gridX, gridY, size);
  fill(white);
}

// Update all cell values for the next draw.
void update() {
  // We loop twice so that cells don't change values based on their
  // neighbors' new values.
  for (int x = 0; x < side; x++) {
    for (int y = 0; y < side; y++) {
      neighbors[x][y] = n(x, y);
    }
  }
  for (int x = 0; x < side; x++) {
    for (int y = 0; y < side; y++) {
      switch (neighbors[x][y]) {
        case 2:
          // Stasis.
          break;
        case 3:
          // Birth.
          cells[x][y] = 1;
          break;
        default:
          // Death.
          cells[x][y] = 0;
      }
    }
  }
}

// Translate cell coordinates to grid coordinates.
int cell_to_grid(int cell) {
  return cell * size;
}

// Translate grid coordinates to cell coordinates.
int grid_to_cell(int grid) {
  return grid / size; // Integer division results in the floor of the floating point value.
}

// The number of live neighbors of cell x,y.
int n(int x, int y) {
  int n = 0;
  for (int xn = -1; xn <= 1; xn++) {
    for (int yn = -1; yn <= 1; yn++) {
      if ((xn == 0) && (yn == 0)) {
        // The original cell.
        continue;
      }
      // Toroidal wrap of cell neighbors.
      int xx = (x + xn + side) % side;
      int yy = (y + yn + side) % side;
      n += cells[xx][yy];
    }
  }
  return n;
}

// Randomize grid.
void randomize() {
  for (int x = 0; x < side; x++) {
    for (int y = 0; y < side; y++) {
      cells[x][y] = round(random(1));
    }
  }
}

// Click on cells to turn them live.
void mousePressed() {
  int x = grid_to_cell(mouseX);
  int y = grid_to_cell(mouseY);
  cells[x][y] = abs(cells[x][y] - 1); // Flip the cell
}

void keyPressed() {
  switch (key) {
    case ('c'):
    case ('C'):
      // Mass extinction!
      cells = new int[side][side];
      continuous = false;
      println("Mass extinction!");
      break;
    case ('r'):
    case ('R'):
      randomize();
      println("Randomize");
      break;
    case ('g'):
    case ('G'):
      println("Toggle step updates.");
      continuous = !continuous;
      break;
    case (' '):
      println("Step.");
      continuous = false;
      update();
      break;
    default:
      break;
  }
}
