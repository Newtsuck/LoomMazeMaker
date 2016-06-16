package utils 
{	
	/**
	 * This class uses internal vector objects to represent a two dimensional maze composed of Maze Units
	 * 
	 * The start of the maze is always the bottom-left unit, and the finish is always the top-right unit
	 * 
	 * The data in this class is primarily accessed by providing an x and y coordinate. These coordinates reflect
	 * the Loom standard, in that the x coordinate begins at the left side and increases as it moves to the right.
	 * The y coordinate begins at the top, and increases as it moves downward.
	 * 
	 * Here is a 3x3 grid with the x and y values of each data slot as it is represented within the class
	 * ----------------------------
	 * | (0, 0) | (1, 0) | (2, 0) |
	 * ----------------------------
	 * | (0, 1) | (1, 1) | (2, 1) |
	 * ----------------------------
	 * | (0, 2) | (1, 2) | (2, 2) |
	 * ----------------------------
	 * 
	 * In the example grid, the unit (0, 2) is the start of the maze, and (2, 0) is the finish
	 */
	public class Maze
	{
		/**
		 * The maximum width or height allowed for a maze
		 */
		private const MAX_DIMENSION_SIZE:Number = 20;
		
		private var _vect:Vector.<MazeUnitData>;
		
		/**
		 * This vector contains the indexes of units that are empty, but have adjacent units that are NOT empty.
		 * This is used for more effective randomization of maze dynamics
		 */
		private var randomSelectionIndexes:Vector.<Number>;
		
		private var _width:Number;
		public function get width():Number { return this._width; }
		
		private var _height:Number;
		public function get height():Number { return this._height; }
		
		/**
		 * The constructor requires the width and height of the maze to be generated
		 * 
		 * @param	w The width
		 * @param	h The height
		 */
		public function Maze(w:Number, h:Number)
		{
			this._width = this.checkDimension(w);
			this._height = this.checkDimension(h);
			
			this.randomSelectionIndexes = new Vector.<Number>;
			
			// Generate the maze (by.. regenerating it)
			this.regenerateMaze();
		}
		
		/**
		 * Creates a brand new maze with the width and height provided. If no width or height are provided,
		 * the current setting will be used.
		 * 
		 * @param	w The width
		 * @param	h The height
		 */
		public function regenerateMaze(w:Number = null, h:Number = null):void
		{
			// Check for null
			if (w != null) this._width = this.checkDimension(w);
			if (h != null) this._height = this.checkDimension(h);
			
			// Instantiate all of the maze units
			this._vect = new Vector.<MazeUnitData>(this._width * this._height);
			var xCount:Number, yCount:Number = 0;
			for (var i = 0; i < this._vect.length; i++)
			{
				this._vect[i] = new MazeUnitData(xCount++, yCount);
				
				// Why use complicated and difficult to understand modulo operations when you can just count?
				if (xCount == this._width)
				{
					xCount = 0;
					yCount++;
				}
				
				// Start or finish?
				if (this._vect[i].xPos == 0 && this._vect[i].yPos == this._height - 1)
					this._vect[i].isStart = true;
					
				if (this._vect[i].xPos == this._width - 1 && this._vect[i].yPos == 0)
					this._vect[i].isFinish = true;
			}
			
			// Let's make a maze!
			var currentUnit:MazeUnitData;
			var previousDirection:Directions;
			
			// First find the start
			for (i = 0; i < this._vect.length; i++)
			{
				if (this._vect[i].isStart)
				{
					// While we are at it, make sure there is only one start
					Debug.assert(currentUnit == null, "More than one starting point detected!");
					currentUnit = this._vect[i];
					
					// Connect either the East or North unit to the start
					var otherUnit:MazeUnitData;
					switch (Random.randRangeInt(0, 1))
					{
						case 0:
							// Connect the east unit
							currentUnit.eastOpen = true;
							otherUnit = getPoint(currentUnit.xPos + 1, currentUnit.yPos);
							otherUnit.westOpen = true;
							break;
						case 1:
							// Connect the north unit
							currentUnit.northOpen = true;
							otherUnit = getPoint(currentUnit.xPos, currentUnit.yPos - 1);
							otherUnit.southOpen = true;
							break;
					}
					
					// Add the two filled units' adjacent empty units to the random selector
					this.addAdjacentUnitsToRandomSelection(currentUnit);
					this.addAdjacentUnitsToRandomSelection(otherUnit);
				}
			}
			
			// Make sure we actually found a start
			Debug.assert(currentUnit != null, "Could not find a starting point to the maze!");
			
			// MAIN MAZE GENERATION LOOP
			while (this.randomSelectionIndexes.length > 0) 
			{
				// Randomly select a unit form the random selection list
				currentUnit = this._vect[this.selectRandomValueFromRandomSelection()];
				
				// Determine what units around our current unit are filled
				var directionVect:Vector.<Directions> = new Vector.<Directions>;
				
				// Check West
				if (currentUnit.xPos + 1 < this._width)
				{
					// We need to make sure we don't connect to the finish in this way. No paths should come out of the finish unit
					var gottenPoint:MazeUnitData = this.getPoint(currentUnit.xPos + 1, currentUnit.yPos);
					if (gottenPoint.isFilled && !gottenPoint.isFinish)
						directionVect.push(Directions.East);
				}
				
				// Check North
				if (currentUnit.yPos - 1 >= 0)
				{
					// Don't connect to the finish from the south, either
					gottenPoint = this.getPoint(currentUnit.xPos, currentUnit.yPos - 1);
					if (gottenPoint.isFilled && !gottenPoint.isFinish)
						directionVect.push(Directions.North);
				}
				
				// Check West
				if (currentUnit.xPos - 1 >= 0)
				{
					if (this.getPoint(currentUnit.xPos - 1, currentUnit.yPos).isFilled)
						directionVect.push(Directions.West);
				}
				
				// Check South
				if (currentUnit.yPos + 1 < this._height)
				{
					if (this.getPoint(currentUnit.xPos, currentUnit.yPos + 1).isFilled)
						directionVect.push(Directions.South);
				}
				
				// If the we didn't find anything than something went terribly wrong!
				Debug.assert(directionVect.length > 0, "Should have found at least one filled, adjacent maze unit! Instead found 0");
				
				// Pick a direction to connect and connect the directions!
				switch (directionVect[Random.randRangeInt(0, directionVect.length - 1)])
				{
					case Directions.East:
						currentUnit.eastOpen = true;
						this.getPoint(currentUnit.xPos + 1, currentUnit.yPos).westOpen = true;
						break;
					case Directions.North:
						currentUnit.northOpen = true;
						this.getPoint(currentUnit.xPos, currentUnit.yPos - 1).southOpen = true;
						break;
					case Directions.West:
						currentUnit.westOpen = true;
						this.getPoint(currentUnit.xPos - 1, currentUnit.yPos).eastOpen = true;
						break;
					case Directions.South:
						currentUnit.southOpen = true;
						this.getPoint(currentUnit.xPos, currentUnit.yPos + 1).northOpen = true;
						break;
				}
				
				// Finally, add the adjacent units to the current unit to the selection vector
				this.addAdjacentUnitsToRandomSelection(currentUnit);
			}
		}
		
		/**
		 * Get the maze unit data at the given point
		 * 
		 * @param	x The X point, along the width
		 * @param	y The Y point, along the height
		 * @return  A MazeUnitData object
		 */
		public function getPoint(x:Number, y:Number):MazeUnitData
		{
			return this._vect[MazeUnitData.calculateIndex(x, y, this._width)];
		}
		
		/**
		 * Uses traces to render the maze in the console
		 * 
		 * The walls of the maze will be rendered in-console with the "X" character, and each maze unit will occupy it's own
		 * 3x3 square
		 * 
		 * Note: The trace function will only trace the first 255 characters of the string, so mazes with an area greater than
		 * 28 units will not be rendered in console properly.
		 * 
		 * @return Returns the generated log string for rendering in-application
		 */
		public function testRender():String
		{
			// Use a string to store everything, and log it all at once
			var logString:String = "";
			
			for (var i = 0; i < this._height; i++)
			{
				// Render the top row of each maze unit
				for (var j = 0; j < this._width * 3; j++)
				{
					// Get the maze unit we are rendering
					var unit:MazeUnitData = this.getPoint(Math.floor(j / 3), i);
					
					// The corners of the grid will always be filled, so we just check the north "exit" to the unit
					if ((j - 1) % 3 == 0)
					{
						if (unit.northOpen) logString += " ";
						else logString += "X";
					}
					else
						logString += "X";
				}
				
				logString += '\n';
				
				// Render the middle row of each maze unit
				for (j = 0; j < this._width * 3; j++)
				{
					// Get the maze unit we are rendering
					unit = this.getPoint(Math.floor(j / 3), i);
					
					// The middle of the grid will always be empty (or indicate the start / finish), so we need to check the east and west "exits" for walls
					if (j % 3 == 0)
					{
						if (unit.westOpen) logString += " ";
						else logString += "X";
					}
					else if ((j - 2) % 3 == 0)
					{
						if (unit.eastOpen) logString += " ";
						else logString += "X";
					}
					else
					{
						// Determine if this is the start or finish
						if (unit.isStart) 
							logString += "S";
						else if (unit.isFinish)
							logString += "F";
						else
							logString += " ";
					}
				}
				
				logString += "\n";
				
				// Render the bottom row of each maze unit
				for (j = 0; j < this._width * 3; j++)
				{
					// Get the maze unit
					unit = this.getPoint(Math.floor(j / 3), i);
					
					// Basically (exactly) the same operation as the top row
					if ((j - 1) % 3 == 0)
					{
						if (unit.southOpen) logString += " ";
						else logString += "X";
					}
					else
						logString += "X";
				}
				
				logString += "\n";
			}
			
			trace(logString);
			return logString;
		}
		
		/**
		 * @private
		 * 
		 * Checks that a dimension (width or height) is within acceptable bounds. If it is not will throw an error! (Assert)
		 * 
		 * @param	d The value of the dimension to be checked
		 * @return  Returns the value passed to it
		 */
		private function checkDimension(d:Number):Number
		{
			// The lower bound is 2, because a maze with either a width or height of 1 would be dumb
			Debug.assert(d >= 2, "Dimension with illegal value! Expected greater than or equal to 2, got " + d);
			Debug.assert(d <= this.MAX_DIMENSION_SIZE, "Dimension with illegal value! Expected less than or equal to " + this.MAX_DIMENSION_SIZE + ", got " + d);
			
			return d;
		}
		
		/**
		 * Takes a MazeUnitData object, and attempts to find and add adjacent units (units immedietly to the east, north, west, or south)
		 * that are empty. Discovered maze units will automatically be added to the random selection
		 * 
		 * @param	unit
		 */
		private function addAdjacentUnitsToRandomSelection(unit:MazeUnitData)
		{
			// Do not do this with the finish
			if (unit.isFinish) return;
			
			// Attempt to find adjacent units, starting with the east side
			if (unit.xPos + 1 < this._width)
			{
				if (!this.getPoint(unit.xPos + 1, unit.yPos).isFilled)
					this.addValueToRandomSelection(MazeUnitData.calculateIndex(unit.xPos + 1, unit.yPos, this._width));
			}
			
			// Now the north side
			if (unit.yPos - 1 >= 0)
			{
				if (!this.getPoint(unit.xPos, unit.yPos - 1).isFilled)
					this.addValueToRandomSelection(MazeUnitData.calculateIndex(unit.xPos, unit.yPos - 1, this._width));
			}
			
			// Now the west siiiieeeed
			if (unit.xPos - 1 >= 0)
			{
				if (!this.getPoint(unit.xPos - 1, unit.yPos).isFilled)
					this.addValueToRandomSelection(MazeUnitData.calculateIndex(unit.xPos - 1, unit.yPos, this._width));
			}
			
			// Finally, the south side
			if (unit.yPos + 1 < this._height)
			{
				if (!this.getPoint(unit.xPos, unit.yPos + 1).isFilled)
					this.addValueToRandomSelection(MazeUnitData.calculateIndex(unit.xPos, unit.yPos + 1, this._width));
			}
		}
		
		/**
		 * Adds a value to the random selection vector. If the value already exists in the array it will not be added
		 * 
		 * @param	value The value to be added to the vector
		 */
		private function addValueToRandomSelection(value:Number):void
		{
			// Check if the value already exists in the vector
			if (this.randomSelectionIndexes.contains(value))
				return;
			
			this.randomSelectionIndexes.push(value);
		}
		
		/**
		 * Removes a value from the random selection vector
		 * 
		 * @param	value The value to be removed
		 */
		private function removeValueFromRandomSelection(value:Number):void
		{
			this.randomSelectionIndexes.remove(value);
		}
		
		/**
		 * Returns a random value from the random selection vector. The value that is returned is automatically removed from the
		 * selection vector
		 * 
		 * @return A randomly selected value. Null if there are no values to select
		 */
		private function selectRandomValueFromRandomSelection():Number
		{
			if (this.randomSelectionIndexes.length == 0)
				return null;
			
			var retIndex:Number = this.randomSelectionIndexes[Random.randRangeInt(0, this.randomSelectionIndexes.length - 1)];
			
			// Remove the number we are returning
			this.removeValueFromRandomSelection(retIndex);
			
			return retIndex;
		}
	}
	
	/**
	 * This class holds data related to a single maze unit
	 */
	public class MazeUnitData 
	{
		/**
		 * Static Function
		 * Calculates the index of a maze unit using a provided x, and y position, along with the width of the maze.
		 * This function should only be used internally to assist with maze altering operations
		 * 
		 * @param	xPos  The X Position of the maze Unit
		 * @param	yPos  The Y Position of the maze Unit 
		 * @param	width The width of the maze
		 * @return The calculated index
		 */
		public static function calculateIndex(xPos:Number, yPos:Number, width:Number):Number
		{
			return xPos + (yPos * width);
		}
		
		/**
		 * If the west side of the maze unit is open for travel (eg: there is NOT a wall in that direction)
		 */
		public var westOpen:Boolean = false;
		
		/**
		 * If the north side of the maze unit is open for travel (eg: there is NOT a wall in that direction)
		 */
		public var northOpen:Boolean = false;
		
		/**
		 * If the east side of the maze unit is open for travel (eg: there is NOT a wall in that direction)
		 */
		public var eastOpen:Boolean = false;
		
		/**
		 * If the south side of the maze unit is open for travel (eg: there is NOT a wall in that direction)
		 */
		public var southOpen:Boolean = false;
		
		/**
		 * If this maze unit is the start of the maze.
		 */
		public var isStart:Boolean = false;
		
		/**
		 * If this maze unit is the finish of the maze.
		 */
		public var isFinish:Boolean = false;
		
		/**
		 * The X position of this maze unit (corrisponds with the first dimention of the maze array)
		 */
		private var _xPos:Number;
		public function get xPos():Number { return this._xPos; }
		
		/**
		 * The Y1 position of this maze unit (corrisponds with the second dimention of the maze array)
		 */
		private var _yPos:Number;
		public function get yPos():Number { return this._yPos; }
		
		/** 
		 * Returns a single number that represents the wall configurations
		 * The number is generated by using bitwise OR operations on the number 0 as a starting point.
		 * 
		 * A wall on the east side will genrate the operation 'value | 0x1'
		 * A wall on the north side will genrate the operation 'value | 0x2'
		 * A wall on the west side will genrate the operation 'value | 0x4'
		 * A wall on the south side will genrate the operation 'value | 0x8'
		 */
		public function get wallConfigNumber():Number
		{
			var num:Number = 0;
			if (this.westOpen == false) num |= 0x1;
			if (this.northOpen == false) num |= 0x2;
			if (this.westOpen == false) num |= 0x4;
			if (this.southOpen == false) num |= 0x8;
			
			return num;
		}
		
		/**
		 * Returns true if this unit has been given openings (has been made part of the maze) and false otherwise
		 */
		public function get isFilled():Boolean
		{
			return (this.eastOpen || this.northOpen || this.westOpen || this.southOpen);
		}
		
		/**
		 * The constructor requires the x and y position of the maze unit
		 * 
		 * @param	xp The X position of the maze unit
		 * @param	yp The Y position of the maze unit
		 */
		public function MazeUnitData(xp:Number, yp:Number) 
		{
			this._xPos = xp;
			this._yPos = yp;
		}
	}
	
	/**
	 * Enum representing the 4 cordinal directions
	 */
	public enum Directions
	{
		East,
		North,
		West,
		South
	}
}