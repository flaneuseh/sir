// README
// 
// SIR Model of Disease Transmission
// An implementation in Processing by Kaylah Facey.
//
//  space bar - Toggle continuous simulation mode.
//  s - Take a single simulation step and stop.
//  digits 1 through 6 - re-initialize the cells based on one of six scenarios:
//    1. No agent movement; infection spreads to most of population.
//    2. No agent movement; infection quickly dies down, leaving most of the population unaffected.
//    3. No agent movement; infection spreads to about half of the population.
//    4. Continuous agent movement; infection spreads to most of population.
//    5. Continuous agent movement; infection quickly dies down, leaving most of the population unaffected.
//    6. Continuous agent movement; infection spreads to about half of the population.

// Initialization parameters.
float p_filled = 1.0;                                                   // Probability that a cell is occupied. When p_filled == 1, there is no cell movement.
float p_infected = .005;                                                // Probability that an agent will begin infected.
float[] p_filled_cases = new float[]{1.0, 1.0, 1.0, .3, .3, .3};        // p_filled for cases 1-6.

// Spread parameters.
float p_transmission = 1.0;                                             // Probability that an agent will infect a given neighbor.
int time_to_recovery = 1;                                               // Time for an agent to recover from infection.
float[] p_transmission_cases = new float[]{1.0, .5, 0, 1.0, .5, 0};     // p_transmission for cases 1-6.
int[] time_to_recovery_cases = new int[]{100, 50, 0, 100, 50, 0};       // time_to_recovery for cases 1-6.

// Cell colours.
color susceptible = color(0, 255, 0);  // green
color infected = color(255, 0, 0);     // red
color recovered = color(0, 0, 255);    // blue
color unoccupied = color(0);           // black

// Simulation parameters.
int cells_per_side = 100;                        // cells per side of grid.
int cell_size = 6;                          // size of a cell.
boolean continuous = false;            // Whether to draw in continuous or single step mode.

int curr_case = 0;                                       // The current case - 1.
color[][] curr_state = new color[cells_per_side][cells_per_side];            // Current state of each cell's agent.
color[][] next_state = new color[cells_per_side][cells_per_side];            // Next state of each cell's agent.
int[][] agent_time_to_recovery = new int[cells_per_side][cells_per_side];    // Time to recovery of each cell's agent.

void setup() {
  size(600, 800);  // cell_size * cells_per_side
  set_case(0);
}

// Update parameters for a new case.
void set_case(int new_case) {
  curr_case = new_case;
  p_filled = p_filled_cases[curr_case];
  p_transmission = p_transmission_cases[curr_case];
  time_to_recovery = time_to_recovery_cases[curr_case];
  initialize();
}

// Fill grid based on current case parameters.
void initialize() {
  continuous = false;
  for (int x = 0; x < cells_per_side; x++) {
    for (int y = 0; y < cells_per_side; y++) {
      if (random(1) < p_filled) {
        curr_state[x][y] = susceptible;
        if (random(1) < p_infected) {
          curr_state[x][y] = infected;
          agent_time_to_recovery[x][y] = time_to_recovery;
        }
      } else {
        curr_state[x][y] = unoccupied;
      }
    }
  }
}

// Update infections and locations of agents.
void update() {
  next_state = deep_copy(curr_state);
  
  // Use a shuffled list to avoid anisotropic behaviour.
  int[][] shuffled_coordinates = shuffle_coordinates(cells_per_side, cells_per_side);
  for (int i = 0; i < shuffled_coordinates.length; i++) {
    int x = shuffled_coordinates[i][0];
    int y = shuffled_coordinates[i][1];
    
    if (curr_state[x][y] == infected) {
      // Update infections of neighbors.
      infect_neighbors(x, y);
      
      // Recover from infection.
      if (agent_time_to_recovery[x][y] == 0) {
        next_state[x][y] = recovered;
      } else {
        agent_time_to_recovery[x][y]--;
      }
    }
    
    if (curr_state[x][y] != unoccupied) {
      // Update location.
      int[][] unoccupied_neighbors = get_unoccupied_neighbors(x, y);
      if (unoccupied_neighbors.length > 0) {
        int move_index = int(random(unoccupied_neighbors.length));
        move_agent(new int[]{x, y}, unoccupied_neighbors[move_index]);
      }
    }
  }
  
  curr_state = deep_copy(next_state);
}

color[][] deep_copy(color[][] original) {
  color[][] copy = new color[original.length][original[0].length];
  for (int x = 0; x < original.length; x++) {
    for (int y = 0; y < original[0].length; y++) {
      copy[x][y] = original[x][y];
    }
  }
  return copy;
}

// Probabilistically infect the (non-diagonal) neighbors of infected agent at cell x, y.
void infect_neighbors(int x, int y) {
  for (int xn = -1; xn <= 1; xn++) {
    for (int yn = -1; yn <= 1; yn++) {
      if (abs(xn) == abs(yn)) {
        // if xn == yn == 0, it is the original cell.
        // if both xn and yn are either 1 or -1, then it is a diagonal neighbor.
        continue;
      }
      // Toroidal wrap of cell neighbors.
      int xx = (x + xn + cells_per_side) % cells_per_side;
      int yy = (y + yn + cells_per_side) % cells_per_side;
      
      if (random(1) < p_transmission && curr_state[xx][yy] == susceptible) {
        next_state[xx][yy] = infected;
        agent_time_to_recovery[xx][yy] = time_to_recovery;
      }
    }
  }
}

// Get the unoccupied (non-diagonal) neighbors of cell x, y.
int[][] get_unoccupied_neighbors(int x, int y) {
  // Start with array of potentially all neighbor coordinates
  int[][] untrimmed_unoccupied_neighbors = new int[4][2]; 
  int cnt = 0;
  for (int xn = -1; xn <= 1; xn++) {
    for (int yn = -1; yn <= 1; yn++) {
      if (abs(xn) == abs(yn)) {
        // if xn == yn == 0, it is the original cell.
        // if both xn and yn are either 1 or -1, then it is a diagonal neighbor.
        continue;
      }
      // Toroidal wrap of cell neighbors.
      int xx = (x + xn + cells_per_side) % cells_per_side;
      int yy = (y + yn + cells_per_side) % cells_per_side;
      
      // Check next_state values as another cell could've already moved into the unoccupied cell.
      if ((curr_state[xx][yy] == unoccupied) && (next_state[xx][yy] == unoccupied)) {
        untrimmed_unoccupied_neighbors[cnt] = new int[]{xx, yy};
        cnt++;
      }
    }
  }
  
  // Trim array to only unoccupied neighbors.
  int[][] trimmed_unoccupied_neighbors = new int[cnt][2];
  for (int i = 0; i < cnt; i++) {
    trimmed_unoccupied_neighbors[i] = untrimmed_unoccupied_neighbors[i];
  }
  return trimmed_unoccupied_neighbors;
}

// Move the agent at curr_pos to next_pos.
void move_agent(int[] curr_pos, int[] next_pos) {
  int curr_x = curr_pos[0];
  int curr_y = curr_pos[1];
  int next_x = next_pos[0];
  int next_y = next_pos[1];
  
  next_state[next_x][next_y] = curr_state[curr_x][curr_y];
  next_state[curr_x][curr_y] = unoccupied;
  // Be sure to move the time_to_recovery with the agent.
  agent_time_to_recovery[next_x][next_y] = agent_time_to_recovery[curr_x][curr_y]; 
}

// Shuffle coordinate values for a grid sized x * y and 
// return a list of all possible x,y pairs, shuffled.
int[][] shuffle_coordinates(int len_x, int len_y) {
  int[][] coordinates = new int[len_x * len_y][2];
  
  // Get ordered list of coordinates.
  for (int x = 0; x < len_x; x++) {
    for (int y = 0; y < len_y; y++) {
      coordinates[(x * len_y) + y] = new int[]{x, y};
    }
  }
  
  // Shuffle coordinates at random.
  for (int i = 0; i < coordinates.length; i++) {
    int shuffle_index = int(random(coordinates.length));
    int[] i_value = coordinates[i];
    int[] shuffle_value = coordinates[shuffle_index];
    
    coordinates[i] = shuffle_value;
    coordinates[shuffle_index] = i_value;
  }
  
  return coordinates;
}

void draw() {
  background(unoccupied);
  for (int x = 0; x < cells_per_side; x++) {
    for (int y = 0; y < cells_per_side; y++) {
      // Populate grid.
      if (curr_state[x][y] != unoccupied) {
        fill(curr_state[x][y]);
        int gridX = cell_to_grid(x);
        int gridY = cell_to_grid(y);
        square(gridX, gridY, cell_size);
      }
    }
  }
  if (continuous) {
    update(); 
  }
}

// Translate cell coordinates to grid coordinates.
int cell_to_grid(int cell) {
  return cell * cell_size;
}

// Translate grid coordinates to cell coordinates.
int grid_to_cell(int grid) {
  // Integer division results in the floor of the floating point value.
  return grid / cell_size; 
}

void keyPressed() {
  switch (key) {
    case ('1'):
    case ('2'):
    case ('3'):
    case ('4'):
    case ('5'):
    case ('6'):
      // Change case.
      println("Set case to " + key);
      set_case(Character.getNumericValue(key) - 1);
      break;
    case (' '):
      // Toggle continuous mode.
      continuous = !continuous;
      break;
    case ('s'):
      // Single step.
      continuous = false;
      update();
      break;
    default:
      break;
  }
}
