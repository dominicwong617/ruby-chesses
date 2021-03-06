require 'colored'
require_relative 'piece'
require_relative 'user'
require_relative 'game'
require 'debugger'

class Board
  attr_accessor :grid

  def initialize(fill=true)
    @grid = Board.create_grid
    fill_board if fill
  end

  def render
    print "abcdefgh\n"
    @grid.each_with_index do |row, row_index|
      row.each_with_index do |piece, col_index|
        print_empty_tiles(row_index, col_index) if piece.nil?
        print_occupied_tiles(piece, row_index, col_index) if piece
      end.join
      puts "\n"
    end.join("\n")
  end

  def tile_at(move_pos)
    raise "Not In Board" unless tile_in_board?(move_pos)

    x, y = move_pos
    @grid[x][y]
  end

  def valid_move?(move_pos)
    tile_in_board?(move_pos) && tile_empty?(move_pos)
  end

  def valid_jump_move?(piece, jump_move, attack_move)
    valid_move?(jump_move) && (tile_at(attack_move).is_a?(Piece) && tile_at(attack_move).color != piece.color)
  end

  def get_move(piece, move)
    from_x, from_y = piece.position
    to_x, to_y = move
    @grid[to_x][to_y] = piece
    piece.position = move
    @grid[from_x][from_y] = nil

    piece.promote_to_king if piece.reached_other_side?
  end

  def capture_piece(attack_move)
    x, y = attack_move
    piece = @grid[x][y]
    piece.position = nil
    @grid[x][y] = nil
  end

  def dup
    board_copy = Board.new(false)
    board_copy.grid.each_with_index do |row, row_index|
      row.each_with_index do |piece, col_index|
        board_copy.grid[row_index][col_index] = self.grid[row_index][col_index].dup unless self.grid[row_index][col_index].nil?
      end
    end
    board_copy
  end

  def game_over?(color)
    one_side_wiped_out?(color) || no_more_moves?(color)
  end

  private

  def tile_in_board?(move_pos)
    move_pos.all? {|coord| coord.between?(0,7)}
  end

  def tile_empty?(move_pos)
    tile_at(move_pos).nil?
  end

  def one_side_wiped_out?(color)
    @grid.each do |row|
      row.each do |piece|
        next if piece.nil?
        return false if piece.color == color
      end
    end
    true
  end

  def no_more_moves?(color)
    @grid.each do |row|
      row.each do |piece|
        next if piece.nil? || piece.color != color
        return false if piece.has_moves?(self)
      end
    end
    true
  end

  def self.create_grid
    @grid = Array.new(8) { Array.new(8) }
  end

  def fill_board
    fill_odd_rows(:red)
    fill_even_rows(:red)
    fill_odd_rows(:black)
    fill_even_rows(:black)
  end

  def fill_odd_rows(color)
    rows = (color == :red) ? [0, 2] : [6]
    rows.each do |row_index|
      (0..7).select(&:odd?).each do |col_index|
        @grid[row_index][col_index] = Piece.new(color, [row_index, col_index])
      end
    end
  end

  def fill_even_rows(color)
    rows = (color == :red) ? [1] : [5, 7]
    rows.each do |row_index|
      (0..7).select(&:even?).each do |col_index|
        @grid[row_index][col_index] = Piece.new(color, [row_index, col_index])
      end
    end
  end

  def print_occupied_tiles(piece, row_index, col_index)
    if piece.color == :red
      print piece.render.red_on_blue if col_index < 7
      print piece.render.red_on_blue + "#{row_index}" if col_index == 7
    else
      print piece.render.black_on_blue if col_index < 7
      print piece.render.black_on_blue + "#{row_index}" if col_index == 7
    end
  end

  def print_empty_tiles(row_index, col_index)
    # print empty even rows
    print " ".on_white if (row_index.even? && col_index.even? && col_index < 7)
    print " ".on_blue if (row_index.even? && col_index.odd? && col_index < 7)
    # print empty odd rows
    print " ".on_blue if (row_index.odd? && col_index.even? && col_index < 7)
    print " ".on_white if (row_index.odd? && col_index.odd? && col_index < 7)
    # print last column
    print " ".on_blue + "#{row_index}" if (row_index.even? && col_index == 7)
    print " ".on_white + "#{row_index}" if (row_index.odd? && col_index == 7)
  end
end
