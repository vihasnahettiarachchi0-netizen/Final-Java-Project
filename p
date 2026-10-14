import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Scanner;
    

//main class
class BloodSupply {

    private String supplyType;
    private int unitsAvailable;

    //constructor to initialize the blood supply with a type and initial units.
    public BloodSupply(String supplyType, int initialUnits) {
        this.supplyType = supplyType;
        setUnitsAvailable(initialUnits);
    }

    public String getSupplyType() {   // Returns the type of blood supply .
        return this.supplyType;
    }

    public int getUnitsAvailable() {
        return this.unitsAvailable;
    } //returns the current number of units available in this blood supply.


    //
    public void setUnitsAvailable(int unitsAvailable) {
        if (unitsAvailable >= 0) {
            this.unitsAvailable = unitsAvailable;
        } else {
            this.unitsAvailable = 0;
        }
    }

    // Simulates the loss of 5% of the current stock each cycle.
    public int applyExpiration() {
        int expiredUnits = (int) (this.unitsAvailable * 0.05);
        this.unitsAvailable -= expiredUnits;
        return expiredUnits;
    }

    // Adds fresh stock from donation drives or emergency sourcing.
    public void addStock(int units) {
        if (units > 0) {
            this.unitsAvailable += units;
        }
    }
}

//child class 1
class EmergencyStock extends BloodSupply {
    public EmergencyStock(int initialUnits) {
        super("Emergency Stock (O Negative)", initialUnits);
    } //constructor

    public boolean checkCriticalAlert() {
        return getUnitsAvailable() < 10;
    }
}


//child class 2
class ScheduledStock extends BloodSupply {
    public ScheduledStock(int initialUnits) {
        super("Scheduled Stock (Type Specific)", initialUnits);
    } //constructor
}

//class to manage patient demand generation for both urgent and routine needs.
class Patient {
    private int urgentDemand;
    private int routineDemand;

    // Randomly generates demand for urgent and routine patients each cycle.
    public void generateDemand() {
        this.urgentDemand = 10 + (int) (Math.random() * 11);
        this.routineDemand = 5 + (int) (Math.random() * 11);
    }

    public int getUrgentDemand() {
        return this.urgentDemand;
    }

    public int getRoutineDemand() {
        return this.routineDemand;
    }
}

// Main class to run the blood bank resource management simulation.
public class Main {
    private static final String SAVE_FILE_NAME = "Dona_bloodBankSave.txt"; // File name for saving and loading simulation state.
    private static final int MAX_CYCLES = 10; // Total number of cycles the simulation will run for

    public static void main(String[] args) {
        Scanner inputScanner = new Scanner(System.in); // Scanner for user input throughout the simulation.

        EmergencyStock emergencyPool = new EmergencyStock(25); // Initializes the emergency stock with 25 units.
        ScheduledStock scheduledPool = new ScheduledStock(50); // Initializes the scheduled stock with 50 units.
        Patient patientManager = new Patient();


        int totalBudget = 10000;  //initialising the total budget
        int totalExpiredUnits = 0; //initialising the total expired units
        int currentCycle = 1; //number of cycles starting at 1

        //printing a welcome meessage
        System.out.println("   WELCOME TO THE BLOOD BANK RESOURCE MANAGER    ");
        System.out.println("-------------------------------------------------");

        // Offers the user the option to load a previous simulation state or start fresh.
        System.out.print("Would you like to load a previous simulation? (yes/no): ");
        String loadChoice = inputScanner.nextLine().trim().toLowerCase();


        //condition to check if the user wants to load a previous simulation.
        if (loadChoice.equals("yes") || loadChoice.equals("y")) {
            int[] loadedData = loadSimulation();  //loads the previous simulation data using the loadSimulation method

            if (loadedData != null) {  // If valid data was loaded, it updates the simulation state accordingly.
                emergencyPool.setUnitsAvailable(loadedData[0]);//updating the emergency stock with the loaded value from the file
                scheduledPool.setUnitsAvailable(loadedData[1]); //updating the scheduled stock with the loaded value from the file
                totalBudget = loadedData[2]; //displays the  budget value from the file
                totalExpiredUnits = loadedData[3]; //displays the total expired units value
                currentCycle = loadedData[4]; //displays the current cycle value from the file

                System.out.println("Previous simulation loaded successfully."); // Displays the loaded state to the user.
            } else {
                System.out.println("No valid saved simulation was found."); // If loading fails, it starts a new simulation.
            }
        } else {
            System.out.println("Starting a new simulation."); // If the user chooses not to load, it simply continues with the initialized state.
        }


        // Main simulation loop that continues until the maximum number of cycles is reached or the budget is depleted.
        while (currentCycle <= MAX_CYCLES && totalBudget > 0) {
            System.out.println("-------------------------------------------------");
            System.out.println("CYCLE " + currentCycle + " of " + MAX_CYCLES);
            System.out.println("-------------------------------------------------");

            // Applies the 5% expiration to both emergency and scheduled stocks
            int emergencyExpired = emergencyPool.applyExpiration();
            int scheduledExpired = scheduledPool.applyExpiration();
            int expiredThisCycle = emergencyExpired + scheduledExpired;
            totalExpiredUnits += expiredThisCycle; // Updates the total count of expired units across all cycles.

            // Generates new patient demand for the current cycle and retrieves the specific urgent and routine needs.
            patientManager.generateDemand();
            int urgentNeeded = patientManager.getUrgentDemand();
            int routineNeeded = patientManager.getRoutineDemand();

            // Displays the current stock levels, remaining budget, expired units, and incoming patient demand for the current cycle.
            System.out.println("Current Stock Levels (After 5% Expiration):");
            System.out.println(" -> " + emergencyPool.getSupplyType() + ": " + emergencyPool.getUnitsAvailable() + " units");
            System.out.println(" -> " + scheduledPool.getSupplyType() + ": " + scheduledPool.getUnitsAvailable() + " units");
            System.out.println("Remaining Financial Capital: £" + totalBudget);
            System.out.println("Expired units discarded this round: " + expiredThisCycle);
            System.out.println("\nIncoming Demand for This Round:");
            System.out.println(" -> Urgent Patient Needs: " + urgentNeeded + " units");
            System.out.println(" -> Routine Patient Needs: " + routineNeeded + " units");
            System.out.println("-------------------------------------------------");

            if (emergencyPool.checkCriticalAlert()) {
                System.out.println("Emergency Stock is below 10 units!"); // Alerts the user if the emergency stock is critically low
            }

            //asking user how many units they want
            int emergencyPurchased = readNonNegativeInt(inputScanner, "Enter amount of Emergency units to source (£15 each): ");
            int scheduledPurchased = readNonNegativeInt(inputScanner, "Enter amount of Scheduled units to source (£8 each): ");

            int purchaseCost = (emergencyPurchased * 15) + (scheduledPurchased * 8); // Calculates the total cost of the user's purchase decisions for this cycle.
            totalBudget -= purchaseCost; // Deducts the purchase cost from the total budget.

            emergencyPool.addStock(emergencyPurchased); // Adds the purchased units to the emergency stock.
            scheduledPool.addStock(scheduledPurchased);// Adds the purchased units to the scheduled stock.


            //To show the start of the patient treatment phase and to check if the current stock can meet the patient demand
            System.out.println("Patient Treatment Phase");

            if (emergencyPool.getUnitsAvailable() >= urgentNeeded) { // Checks if the emergency stock can fully meet the urgent patient demand.
                emergencyPool.setUnitsAvailable(emergencyPool.getUnitsAvailable() - urgentNeeded); // If it can, it deducts the used units from the emergency stock
                System.out.println("Successfully fulfilled all urgent patient demands.");
            } else { // If it cannot, it calculates the shortage and applies a penalty cost
                int shortage = urgentNeeded - emergencyPool.getUnitsAvailable();
                int penaltyCost = shortage * 40;
                totalBudget -= penaltyCost;
                emergencyPool.setUnitsAvailable(0);
                System.out.println("SHORTAGE! Emergency stock depleted. Emergency buy in cost: £" + penaltyCost);
            }

            if (scheduledPool.getUnitsAvailable() >= routineNeeded) { // Checks if the scheduled stock can fully meet the routine patient demand.
                scheduledPool.setUnitsAvailable(scheduledPool.getUnitsAvailable() - routineNeeded);
                System.out.println("Successfully fulfilled all routine patient demands.");
            } else { // If it cannot, it calculates the shortage and applies a penalty cost
                int shortage = routineNeeded - scheduledPool.getUnitsAvailable();
                int penaltyCost = shortage * 25;
                totalBudget -= penaltyCost;
                scheduledPool.setUnitsAvailable(0);
                System.out.println("[SHORTAGE] Scheduled stock depleted. Premium fallback cost: £" + penaltyCost);
            }

            // Displays a summary of the cycle's outcomes,
            System.out.println("Cycle Summary Outcomes:");
            System.out.println(" -> Final Emergency Inventory: " + emergencyPool.getUnitsAvailable() + " units");
            System.out.println(" -> Final Scheduled Inventory: " + scheduledPool.getUnitsAvailable() + " units");
            System.out.println(" -> End of Cycle Financial Capital: £" + totalBudget);

            currentCycle++; // Increments the cycle counter to move to the next cycle.

            // Saves the current state of the simulation at the end of each cycle
            saveSimulation(
                    emergencyPool.getUnitsAvailable(),
                    scheduledPool.getUnitsAvailable(),
                    totalBudget,
                    totalExpiredUnits,
                    currentCycle
            );

            System.out.println("Simulation progress saved to " + SAVE_FILE_NAME + "."); //displays a message confirming that the current state has been saved to the specified file.


            // After saving, it checks if the simulation can continue to the next cycle based on the current cycle count and remaining budget.
            if (currentCycle <= MAX_CYCLES && totalBudget > 0) {
                System.out.print("Continue to the next cycle? (yes/no): ");
                String continueChoice = inputScanner.next().trim().toLowerCase();

                if (continueChoice.equals("no") || continueChoice.equals("n")) { // If the user chooses not to continue, it exits the simulation loop and ends the program.
                    System.out.println("Exiting safely. Your progress has already been saved.");
                    inputScanner.close();
                    return;
                }
            }
        }


        //display the final results .
        System.out.println("               SIMULATION OVERVIEW               ");
        System.out.println("-------------------------------------------------");
        System.out.println("Total cumulative expired components scrapped: " + totalExpiredUnits + " units");

        if (totalBudget > 0 && emergencyPool.getUnitsAvailable() >= 10) { // If the simulation ended with a positive budget and the emergency stock is above the critical threshold, it is successfull
            System.out.println("SUCCESS: You completed the operational timeframe with a secure configuration.");
            System.out.println("Remaining Emergency Capital Surplus: £" + totalBudget);
        } else { // If the simulation ended with a depleted budget or critically low emergency stock, it is a failure.
            System.out.println("FAILURE: The blood bank is in a critical state.");
            System.out.println("Final Account Value balance: £" + totalBudget); // Displays the final financial state of the simulation.
            System.out.println("Final Emergency Units remaining: " + emergencyPool.getUnitsAvailable()); // Displays the final emergency stock level
        }

        //saves the final state of the simulation
        saveSimulation(
                emergencyPool.getUnitsAvailable(),
                scheduledPool.getUnitsAvailable(),
                totalBudget,
                totalExpiredUnits,
                currentCycle
        );

        System.out.println("Final simulation state saved to " + SAVE_FILE_NAME + "."); // Confirms that the final state has been saved to the specified file.
        System.out.println("-------------------------------------------------------");
        inputScanner.close(); // Closes the scanner
    }

    // Reusable validation method that keeps asking until the user enters a valid whole number.
    public static int readNonNegativeInt(Scanner inputScanner, String promptMessage) {
        while (true) { //it iterates until user enter a valid non negative integer
            System.out.print(promptMessage);

            if (inputScanner.hasNextInt()) { // Checks if the next input is an integer
                int userValue = inputScanner.nextInt();

                if (userValue >= 0) { // If the integer is non negative, it returns the value to be used
                    return userValue;
                } else {
                    System.out.println("Error: Please enter 0 or a positive number."); // If the integer is negative, it displays an error message
                }
            } else {
                System.out.println("Invalid input. Please enter a whole number."); // If the input is not an integer, it displays an error message
                inputScanner.next();
            }
        }
    }

    // Saves the key simulation data at the end of each cycle.
    public static void saveSimulation(int emergencyUnits, int scheduledUnits, int budget, int expiredUnits, int nextCycle) {
        try {
            FileWriter fileWriter = new FileWriter(SAVE_FILE_NAME);

            // Writes the current state of the simulation to the file in a simple format
            fileWriter.write("emergency Units :  "+emergencyUnits + "\n");
            fileWriter.write("scheduled Units:  "+ scheduledUnits+ "\n");
            fileWriter.write("Budget Remaining : " +budget+ "\n");
            fileWriter.write("Expired Units : " + expiredUnits + "\n");
            fileWriter.write("Next Cycle : " + nextCycle+ "\n");

            fileWriter.close(); // Closes the file writer to ensure data is saved properly.
        } catch (IOException error) { // If an error occurs during the file writing process, it catches the exception and displays an error message to the user.
            System.out.println("Save error: The simulation could not be saved.");
        }
    }

    // Loads the previous simulation data if a valid save file exists.
    public static int[] loadSimulation() {
        try { // Attempts to read the saved simulation state from the specified file.
            File saveFile = new File(SAVE_FILE_NAME);
            Scanner fileScanner = new Scanner(saveFile);

            // Reads the saved values from the file in the same order they were written and stores them in variables.
            int emergencyUnits = fileScanner.nextInt();
            int scheduledUnits = fileScanner.nextInt();
            int budget = fileScanner.nextInt();
            int expiredUnits = fileScanner.nextInt();
            int nextCycle = fileScanner.nextInt();

            fileScanner.close(); // Closes the file scanner after reading the data.

            return new int[] { emergencyUnits, scheduledUnits, budget, expiredUnits, nextCycle }; // Returns the loaded data as an array
        } catch (FileNotFoundException error) { // If the file does not exist, it catches the exception and informs the user that no save file was found
            System.out.println("Load error: Save file was not found.");
            return null;
        } catch (Exception error) { // If any other error occurs during the loading process , it catches the exception and informs the user that the save file contains invalid data.
            System.out.println("Load error: Save file exists but contains invalid data.");
            return null;
        }
    }
}
