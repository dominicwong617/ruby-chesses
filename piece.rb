require_relative 'board'
require_relative 'user'
require 'debugger'

class Piece
  attr_reader :color, :symbol
  attr_accessor :is_king, :position
  alias_method :is_king?, :is_king

  def initialize(color, position, is_king=false)
    @color = color
    @is_king = is_king
    @symbol = (color == :red) ? "\u25cf" : "\u25cf"
    @position = position
    @forward_direction = (color == :red) ?  1 : -1
    # black chess king symbol's unicode is "\u265a", to be changed when @is_king == true
  end

  def render
    self.symbol
  end

  def dup
    self.class.new(self.color, self.position, self.is_king)
  end

  def has_moves?(board)
    has_slide_moves?(board) || has_jump_moves?(board)
  end

  def has_slide_moves?(board)
    slide_moves.each do |slide_move|
      return true if board.valid_move?(slide_move)
    end
    false
  end

  def has_jump_moves?(board)
    jump_moves.each do |jump_move|
      attack_move = [(jump_move[0] + self.position[0]) / 2, (jump_move[1] + self.position[1]) / 2]
      return true if board.valid_jump_move?(self, jump_move, attack_move)
    end
    false
  end

  def slide_moves
    [[@forward_direction + @position[0], @position[1] + 1],
     [@forward_direction + @position[0], @position[1] - 1]]
  end

  def perform_slide(board, slide_move)
    begin
      raise InvalidMoveError unless board.valid_move?(slide_move) && slide_moves.include?(slide_move)
    rescue InvalidMoveError => e
      puts "#{e.message}"
    else
      board.get_move(self, slide_move)
    end
  end

  def jump_moves
    [[@forward_direction * 2 + @position[0], @position[1] + 2],
     [@forward_direction * 2 + @position[0], @position[1] - 2]]
  end

  def perform_jump(board, jump_move)
    begin
      attack_move = [(jump_move[0] + self.position[0]) / 2, (jump_move[1] + self.position[1]) / 2]
      raise InvalidMoveError.new unless board.valid_jump_move?(self, jump_move, attack_move) && jump_moves.include?(jump_move)
    rescue InvalidMoveError => e
      puts "#{e.message}"
    else
      board.get_move(self, jump_move)
      board.capture_piece(attack_move)
    end
  end

  def perform_moves!(move_sequence, board)
    # should perform the moves one-by-one. If a move in the sequence fails, an InvalidMoveError should be raised.
    # should not bother to try to restore the original Board state if the move sequence fails.
    move = move_sequence.first # if this is nil, will it crash the method when passed into valid_move?(move) ?

    until move_sequence.empty?
      move = move_sequence.shift
      attack_move = [(move[0] + self.position[0]) / 2, (move[1] + self.position[1]) / 2]

      begin
        raise InvalidMoveError.new unless (board.valid_jump_move?(self, move, attack_move) || board.valid_move?(move))
      rescue InvalidMoveError => e
        puts "#{e.message}"
        return
      else
        if board.valid_jump_move?(self, move, attack_move) && jump_moves.include?(move)
          perform_jump(board, move) # after this step, you can only jump, not move
          has_jumped = true
        elsif board.valid_move?(move) && slide_moves.include?(move) && has_jumped == false
          perform_slide(board, move)
          return  # breaks the loop
        end
      end
    end
  end

  def perform_moves(move_sequence, board)
   # checks valid_move_seq?, and either calls perform_moves! or raises an InvalidMoveError.
   if valid_move_seq?(move_sequence, board)
     perform_moves!(move_sequence, board)
   else
     raise InvalidMoveError
   end
  end

  def valid_move_seq?(move_sequence, board)
    # calls perform_moves! on a duped Piece/Board. If no error is raised, return true; else false.
    # This will of course require begin/rescue/else.
    # Because we dup the objects, valid_move_seq? should not modify the original Board.
    board_copy = board.dup
    piece_copy = self.dup
    begin
      piece_copy.perform_moves!(move_sequence, board_copy)
    rescue InvalidMoveError
      return false
    else
      true
    end
  end
end


class InvalidMoveError < StandardError
  attr_reader :message

  def initialize
    @message = "Invalid Move!"
  end
end