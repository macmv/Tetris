#! /usr/local/bin/ruby

require "gosu"
require "set"

class Point

  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

end

module Tetris

BLOCKSIZE = 20
BLOCKWIDTH = 8
BLOCKHEIGHT = 15
WIDTH = BLOCKWIDTH * BLOCKSIZE
HEIGHT = BLOCKHEIGHT * BLOCKSIZE

private

class Board

  def initialize
    @blocks = Set.new
    @type_data = {0 => {:shape => [Point.new(0, 0), # box
                                   Point.new(1, 0),
                                   Point.new(0, 1),
                                   Point.new(1, 1)],
                        :col => 0xff_ff0000},
                  1 => {:shape => [Point.new(0, 0), # t
                                   Point.new(-1, 0),
                                   Point.new(1, 0),
                                   Point.new(0, 1)],
                        :col => 0xff_00ff00},
                  2 => {:shape => [Point.new(-1, 0), # line
                                   Point.new(0, 0),
                                   Point.new(1, 0),
                                   Point.new(2, 0)],
                        :col => 0xff_00ffff},
                  3 => {:shape => [Point.new(-1, 0), # --
                                   Point.new(0, 0),  #  --
                                   Point.new(0, 1),
                                   Point.new(1, 1)],
                        :col => 0xff_ff00ff},
                  4 => {:shape => [Point.new(0, 0),#  --
                                   Point.new(1, 0), # --
                                   Point.new(0, 1),
                                   Point.new(-1, 1)],
                        :col => 0xff_ff8800},
                  5 => {:shape => [Point.new(0, 0), # l
                                   Point.new(0, 1),
                                   Point.new(0, 2),
                                   Point.new(1, 2)],
                        :col => 0xff_ffff00},
                  6 => {:shape => [Point.new(0, 0), # reverse l
                                   Point.new(0, 1),
                                   Point.new(0, 2),
                                   Point.new(-1, 2)],
                        :col => 0xff_0000ff}}
    @moving_piece = Piece.new @type_data
  end

  def draw
    @blocks.each do |block|
      block.draw
    end
    @moving_piece.draw
  end

  def move_piece_down
    hit_piece_or_wall = @moving_piece.move_down(@blocks)
    if hit_piece_or_wall
      @moving_piece.get_blocks.each do |block|
        @blocks.add block
      end
      @moving_piece = Piece.new @type_data
      BLOCKHEIGHT.times do |row|
        var = false
        BLOCKWIDTH.times do |item|
          @blocks.each do |block|
            if block.x != item && block.y != row
              puts block.x.inspect
              var = true
              break
            end
          end
          break if var
        end
        if !var
          puts
          new_blocks = Set.new
          @blocks.each do |block|
            if block.y < row
              block.y += 1
              new_blocks.add block
            elsif block.y > row
              new_blocks.add block
            end
          end
          @blocks = new_blocks
        end
      end
    end
  end

  def turn_piece_left
    hit_piece_or_wall = @moving_piece.rotate_left(@blocks)
    if hit_piece_or_wall
      @moving_piece.get_blocks.each do |block|
        @blocks.add block
      end
      @moving_piece = Piece.new @type_data
    end
  end

  def turn_piece_right
    hit_piece_or_wall = @moving_piece.rotate_right(@blocks)
    if hit_piece_or_wall
      @moving_piece.get_blocks.each do |block|
        @blocks.add block
      end
      @moving_piece = Piece.new @type_data
    end
  end

  def move_piece_left
    hit_piece_or_wall = @moving_piece.move_left(@blocks)
    if hit_piece_or_wall
      @moving_piece.get_blocks.each do |block|
        @blocks.add block
      end
      @moving_piece = Piece.new @type_data
    end
  end

  def move_piece_right
    hit_piece_or_wall = @moving_piece.move_right(@blocks)
    if hit_piece_or_wall
      @moving_piece.get_blocks.each do |block|
        @blocks.add block
      end
      @moving_piece = Piece.new @type_data
    end
  end

end

class Piece

  attr_reader :shape, :x, :y, :id

  def initialize(type_data, x = BLOCKWIDTH / 2, y = 0, id = nil)
    @x = x
    @y = y
    if id == nil
      @id = rand(7)
    else
      @id = id
    end
    type = type_data[@id]
    @shape = []
    type[:shape].each do |point|
      @shape.push PieceBlock.new(point.x, point.y)
    end
    @col = type[:col]
  end

  def draw
    @shape.each do |block|
      block.draw(@x, @y, @col)
    end
  end

  def move_down(blocks)
    @y += 1
    @shape.each do |block|
      if block.touching?(@x, @y, blocks)
        @y -= 1
        return true
      end
    end
    false
  end

  def rotate_left(pieces)
    @shape.each do |block|
      block.rotate_left
    end
    @shape.each do |block|
      if block.touching?(@x, @y, pieces)
        self.rotate_right pieces
        return true
      end
    end
    false
  end

  def rotate_right(pieces)
    @shape.each do |block|
      block.rotate_right
    end
    @shape.each do |block|
      if block.touching?(@x, @y, pieces)
        self.rotate_left pieces
        return true
      end
    end
    false
  end

  def move_left(pieces)
    if @x > 0
      @x -= 1
      @shape.each do |block|
        if block.touching?(@x, @y, pieces)
          @x += 1
          return true
        end
      end
    end
    false
  end

  def move_right(pieces)
    if @x < BLOCKWIDTH - 2
      @x += 1
      @shape.each do |block|
        if block.touching?(@x, @y, pieces)
          @x -= 1
          return true
        end
      end
    end
    false
  end

  def has_block(x, y)
    @shape.each do |block|
      return true if block.x == x && block.y == y
    end
    false
  end

  def del_row(row)
    new_shape = []
    @shape.each do |row|
      var = block.del_row @x, @y, row
      if var == true
        new_shape.push block
      end
    end
    @shape = new_shape
  end

  def get_blocks
    s = Set.new
    @shape.each do |block|
      s.add Block.new (block.x + @x), (block.y + @y), @col
    end
    s
  end

end

class PieceBlock

  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def draw(x, y, col)
    Gosu.draw_rect((@x + x) * BLOCKSIZE + 1, (@y + y) * BLOCKSIZE + 1, BLOCKSIZE - 2, BLOCKSIZE - 2, col)
  end

  def rotate_left
    new_x = @y
    new_y = @x
    @x = new_x
    @y = new_y * -1
  end

  def rotate_right
    new_x = @y
    new_y = @x
    @x = new_x * -1
    @y = new_y
  end

  def touching?(x, y, blocks)
    if (@y + y) >= BLOCKHEIGHT
      return true
    end
    blocks.each do |block|
      if (@x + x) == block.x && (@y + y) == block.y
        return true
      end
    end
    false
  end

  def del_row(x, y, row)
    tmp_x = @x + x
    tmp_y = @y + y
    if tmp_y < row # above
      @y += 1
    elsif tmp_y == row # on row
      return nil
    end
    true
  end

end

class Block

  attr_reader :x, :y
  
  def initialize(x, y, col)
    @x = x
    @y = y
    @col = col
  end

  def draw
    Gosu.draw_rect(@x * BLOCKSIZE + 1, @y * BLOCKSIZE + 1, BLOCKSIZE - 2, BLOCKSIZE - 2, @col)
  end

end

public

class Screen < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    @board = Board.new
    @prev_time = Time.new
  end

  def draw
    (HEIGHT / 20).times do |y|
      (WIDTH / 20).times do |x|
        Gosu.draw_rect(x * BLOCKSIZE + 1, y * BLOCKSIZE + 1, BLOCKSIZE - 2, BLOCKSIZE - 2, 0xff_ccffff)
      end
    end
    @board.draw
  end

  def update
    if Time.new - @prev_time >= 0.5 || Gosu::button_down?(Gosu::KbS) || Gosu::button_down?(Gosu::KbDown)
      @prev_time = Time.new
      @board.move_piece_down
    end
  end

  def button_down(id)
    if id == Gosu::KbLeft
      @board.turn_piece_left
    elsif id == Gosu::KbRight
      @board.turn_piece_right
    elsif id == Gosu::KbA
      @board.move_piece_left
    elsif id == Gosu::KbD
      @board.move_piece_right
    end
  end

end

end

Tetris::Screen.new.show