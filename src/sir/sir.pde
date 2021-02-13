// README
// 
// SIR Model of Disease Transmission
// An implementation in Processing by Kaylah Facey.
//
//  space bar - Toggle continuous simulation mode.
//  s - Take a single simulation step and stop.
//  digits 1 through 6 - re-initialize the cells based on one of six scenarios:
//    1. No agent movement; infection spreads to most of population. (>80%)
//    2. No agent movement; infection quickly dies down, leaving most of the population unaffected. (<20%)
//    3. No agent movement; infection spreads to about half of the population. (40%-60%)
//    4. Continuous agent movement; infection spreads to most of population. (>80%)
//    5. Continuous agent movement; infection quickly dies down, leaving most of the population unaffected. (<20%)
//    6. Continuous agent movement; infection spreads to about half of the population. (40%-60%)

// Initialization parameters.
float p_filled = 1.0;                                                   // Probability that a cell is occupied. When p_filled == 1, there is no cell movement.
float p_infected = .005;                                                // Probability that an agent will begin infected.
float[] p_filled_cases = new float[]{1.0, 1.0, 1.0, .3, .3, .3};        // p_filled for cases 1-6.

// Spread parameters.
float p_transmission = 1.0;                                             // Probability that an agent will infect a given neighbor.
int time_to_recovery = 1;                                               // Time for an agent to recover from infection.
float[] p_transmission_cases = new float[]{.05, .035, .0413, .12, .08, .1};     // p_transmission for cases 1-6.
int[] time_to_recovery_cases = new int[]{15, 13, 14, 30, 18, 20};       // time_to_recovery for cases 1-6.

// Colours.
color susceptible = color(0, 200, 0);  // green
color infected = color(200, 0, 0);     // red
color recovered = color(0, 0, 200);    // blue
color unoccupied = color(0);           // black
color white = color(255);

// Simulation parameters.
int cells_per_side = 100;                        // cells per side of grid.
int cell_size = 6;                               // size of a cell.
boolean continuous = false;                      // Whether to draw in continuous or single step mode.

int curr_case = 0;                                                           // The current case - 1.
color[][] curr_state = new color[cells_per_side][cells_per_side];            // Current state of each cell's agent.
color[][] next_state = new color[cells_per_side][cells_per_side];            // Next state of each cell's agent.
int[][] agent_time_to_recovery = new int[cells_per_side][cells_per_side];    // Time to recovery of each cell's agent.

// Tracking SIR
int[] s_cnt;
int[] i_cnt;
int[] r_cnt;
int time;

void setup() {
  size(600, 850);  // cell_size * cells_per_side; cell grid + sir graph
  set_case(0);
}

// Update parameters for a new case.
void set_case(int new_case) {
  curr_case = new_case;
  p_filled = p_filled_cases[curr_case];
  p_transmission = p_transmission_cases[curr_case];
  time_to_recovery = time_to_recovery_cases[curr_case];
  println("New parameters: " + p_transmission + ", " + time_to_recovery);
  initialize();
}

// Fill grid based on current case parameters.
void initialize() {
  time = 0;
  int graph_w = cell_size * cells_per_side;
  s_cnt = new int[graph_w]; 
  i_cnt = new int[graph_w];
  r_cnt = new int[graph_w];
  
  continuous = false;
  for (int x = 0; x < cells_per_side; x++) {
    for (int y = 0; y < cells_per_side; y++) {
      if (random(1) < p_filled) {
        if (random(1) < p_infected) {
          curr_state[x][y] = infected;
          agent_time_to_recovery[x][y] = time_to_recovery;
          i_cnt[0]++;
        } else {
          curr_state[x][y] = susceptible;
          s_cnt[0]++;
        }
      } else {
        curr_state[x][y] = unoccupied;
      }
    }
  }
  
  println("time: " + time);
  println("population: " + (s_cnt[time] + i_cnt[time] + r_cnt[time]));
  println("s: " + s_cnt[time]);
  println("i: " + i_cnt[time]);
  println("r: " + r_cnt[time]);
}

// Update infections and locations of agents.
void update() {
  // Start with copy of current state.
  next_state = deep_copy(curr_state);
  if (time >= s_cnt.length - 1) {
    time = s_cnt.length - 2;
    shift_time_cnts();
  }
  s_cnt[time + 1] = s_cnt[time];
  i_cnt[time + 1] = i_cnt[time];
  r_cnt[time + 1] = r_cnt[time];
  
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
        recover(x, y);
      } else {
        agent_time_to_recovery[x][y]--;
      }
    }
  }
  
  // Movement after infection so that cells only infect neighbors that were present before movement.
  // Don't bother attempting movement if p_filled is 1.
  if (p_filled < 1) {
    for (int i = 0; i < shuffled_coordinates.length; i++) {
      int x = shuffled_coordinates[i][0];
      int y = shuffled_coordinates[i][1];
      
      if (curr_state[x][y] != unoccupied) {
        // Update location.
        int[][] unoccupied_neighbors = get_unoccupied_neighbors(x, y);
        if (unoccupied_neighbors.length > 0) {
          int move_index = int(random(unoccupied_neighbors.length));
          move_agent(new int[]{x, y}, unoccupied_neighbors[move_index]);
        }
      }
    }
  }
  
  // Move into new state.
  curr_state = deep_copy(next_state);
  time++;
  
  println("time: " + time);
  println("population: " + (s_cnt[time] + i_cnt[time] + r_cnt[time]));
  println("s: " + s_cnt[time]);
  println("i: " + i_cnt[time]);
  println("r: " + r_cnt[time]);
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
      
      // Check value of next_state to ensure that the cell isn't infected twice.
      if (random(1) < p_transmission && next_state[xx][yy] == susceptible) {
        infect(xx, yy);
      }
    }
  }
}

void infect(int x, int y) {
  next_state[x][y] = infected;
  agent_time_to_recovery[x][y] = time_to_recovery;
  i_cnt[time + 1]++;
  s_cnt[time + 1]--;
}

void recover(int x, int y) {
  next_state[x][y] = recovered;
  r_cnt[time + 1]++;
  i_cnt[time + 1]--;
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
      
      // Move based on next state values to prevent 2 cells moving into the same space
      // (and losing the agent). Agents may move into neighboring positions that are 
      // vacated in the same timestep.
      if (next_state[xx][yy] == unoccupied) {
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
  
  // Move state and time to recovery; set current location to unoccupied.
  next_state[next_x][next_y] = next_state[curr_x][curr_y]; // We move the next state instead of the current state 
                                                           // because infections happen before movement.
  agent_time_to_recovery[next_x][next_y] = agent_time_to_recovery[curr_x][curr_y]; 
  next_state[curr_x][curr_y] = unoccupied;
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
  
  draw_cell_grid();
  draw_sir_graph();
  
  if (continuous) {
    update(); 
  }
}

void draw_cell_grid() {
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
}

int graph_area_h = 250;
void draw_sir_graph() {
  // Initialize graph.
  fill(white);
  int w = cell_size * cells_per_side;
  int h = graph_area_h;
  
  // Graph begins the row after the cells.
  int gridX = 0;
  int gridY = cell_to_grid(cells_per_side);
  
  rect(gridX, gridY, w, h);
  
  // Fill graph.
  noStroke();
  for (int t = 0; t <= time; t++) {
    int s = s_cnt[t];
    int i = i_cnt[t];
    int r = r_cnt[t];
    
    plot(s, t, susceptible);
    plot(i, t, infected);
    plot(r, t, recovered);
  }
  stroke(0);
}

// Plotting parameters.
int window_h = (cell_size * cells_per_side) + graph_area_h; // Height of entire window.
int text_h = 10;                                   // Height of text labels.
int graph_h = 250 - text_h;                        // Height of graph.
int plot_size = 2;                                 // Size of plotted points.
int buffer = cell_size;                            // Buffer between graph and delineating lines.
int useable_graph_h = graph_h - (2 * buffer);            // Useable graph height.

// Plot the state with count cnt at time t.
void plot(float cnt, int t, color state) {
  fill(state);
  
  // Absolute values of all counts.
  int s = s_cnt[t];
  int i = i_cnt[t];
  int r = r_cnt[t];
  float pop = s + i + r;
  
  // Proportion of state represented.
  float pct = cnt/pop;
  int graph_y = round(useable_graph_h * pct);
  
  // graph_y is from the bottom of the graph. We need an absolute value in the window.
  int window_y = window_h - text_h - buffer - graph_y;
  
  int plot_size = cell_size/2;
  circle(t, window_y, plot_size);
  
  if (t == time) { // Only label percents at the current time.
  
    int text_x = 0;
    if (state == susceptible) {
      text_x = 75;
    } else if (state == infected) {
      text_x = 275;
    } else if (state == recovered) {
      text_x = 475;
    }
    int text_y = window_h - 2; // Text is at the very bottom of the window.
    text(pct + "%", text_x, text_y);
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

// Preserve only the most recent counts, so that the graph appears to scroll with time.
void shift_time_cnts() {
  for (int t = 1; t < s_cnt.length; t++) {
    s_cnt[t-1] = s_cnt[t];
    i_cnt[t-1] = i_cnt[t];
    r_cnt[t-1] = r_cnt[t];
  }
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
