require_relative 'game'
require_relative 'db'

class GameManager
  def initialize
    restore_previous_games
  end

  def game(id)
    @games = {} if @games.nil?
    @games[id] if @games.include?(id)
  end

  def start(id)
    @games = {} if @games.nil?
    @games[id] = Game.new(chat_id: id) unless @games.include?(id)
    Constants::START
  end

  def stop(id)
    @games = {} if @games.nil?
    if on?(id)
      @games.delete(id)
      @db.delete_random(:random, chat_id: id)
    end
    Constants::STOP
  end

  def on?(id)
    return false if @games.nil?
    @games.include?(id)
  end

  def restore_previous_games
    @db ||= Database.new
    @games = {} if @games.nil?
    games_of_random_mode = @db.list_of_games(:random)
    games_of_random_mode.each do |chat_id|
      chat_id = chat_id.to_i
      question = @db.question(:random, chat_id: chat_id)
      sources = @db.sources(chat_id: chat_id)
      @games[chat_id] = Game.new(chat_id: chat_id,
                                 tour_name: question['tour_name'],
                                 question_id: question['question_id'],
                                 asked: question['asked'],
                                 sources: sources)
    end
  end

  def post_answer_to_game(id, mode: :normal)
    unless mode == :i_am_a_cheater
      @db.set_asked_to_false(:random, chat_id: id)
    end
    game(id).post_answer(mode: mode)
  end

  def check_suggestion_in_game(id, message)
    correct, text_to_return = game(id).check_suggestion(message)
    @db.set_asked_to_false(:random, chat_id: id) if correct
    text_to_return
  end

  def new_question_for_game(id)
    new_question = game(id).new_question
    @db.save_asked(:random, chat_id: id, tour_name: new_question.tour_name, question_id: new_question.id)
    new_question.text
  end

  def change_sources_state(id)
    game(id).change_sources_state
    current_state = game(id).sources
    @db.set_sources_state(:random, chat_id: id, sources: current_state)
    current_state ? Constants::SOURCES_NOW_ON : Constants::SOURCES_NOW_OFF
  end
end