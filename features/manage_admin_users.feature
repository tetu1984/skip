Feature: 管理者がユーザを管理する
  管理者としてユーザを管理する

  Background:
    Given  言語は"ja-JP"
    And    "a_user"でログインする

  Scenario: 新規のユーザを未使用ユーザとして登録する
    Then   "マイページ"にアクセスする
    And    "システムの管理"リンクをクリックする
    And    "ユーザ管理"リンクをクリックする

    Then   "管理画面のユーザ一覧"ページを表示していること

    When   "新規ユーザの作成"リンクをクリックする
    And    "ログインID"に"newuser0001"と入力する
    And    "名前"に"新規 一郎"と入力する
    And    "メールアドレス"に"newuser@example.com"と入力する
    And    "作成"ボタンをクリックする

#    ユーザ名が空になっていること
    Then   "newuser0001"が"2"回以上表示されていないこと
