require_relative 'common'

# encoding: utf-8
class RestoringFromDbTest < Test::Unit::TestCase
  include Common

  def setup
    @processor = BotProcessorMock.new
    @chat = Telegram::Bot::Types::Chat.new(type: 'group', id: '123', first_name: 'Group', last_name: 'User')
    change_question_to('two_questions_no_pass_criteria.xml')
    send_message('/start')
    send_message('/next')
  end

  def teardown
    send_message('/stop')
  end

  def test_killing_after_next
    erase_and_restore_all_games
    send_message('/answer')
    expected = "*Ответ*: Быть\n*Комментарий*: Замечательный комментарий."
    assert_equal(expected, @reply.message, 'Incorrect message on /answer')
  end

  def test_next_after_surrender_does_not_contain_previous_answer
    send_message('/answer')
    erase_and_restore_all_games
    send_message('/next')
    assert_nil(@reply.previous_answer, 'Previous answer is not nil after restoring from db')
  end

  def test_next_after_answer_does_not_contain_previous_answer
    send_message('/быть')
    erase_and_restore_all_games
    send_message('/next')
    assert_nil(@reply.previous_answer, 'Previous answer is not nil after restoring from db')
  end

  def test_sources_saved_after_restore
    send_message('/sources')
    erase_and_restore_all_games
    send_message('/next')
    assert_include(@reply.previous_answer, '*Источники*:', 'Previous answer is not nil after restoring from db')
  end
end