#!/bin/bash

# enforce-uv.sh
# uvを使用するように強制するフック
# ref. Claude Codeの指示忘れ問題を解決！HooksでPython環境をpip禁止＆uv統一にする https://zenn.dev/gotalab/articles/2fe8d7a15409c8

# ===== 関数定義 =====

# pip installコマンドの処理
function handle_pip_install() {
    local pip_cmd="$1"
    local packages=$(echo "$pip_cmd" | sed 's/install//' | sed 's/--[^ ]*//g' | xargs)

    # -r requirements.txt
    if [[ "$pip_cmd" =~ -r\ .*\.txt ]]; then
        local req_file=$(echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
        cat <<- EOF
		{
		  "decision": "block",
		  "reason": "📋 requirements.txtからインストール:

		✅ 推奨方法:
		uv add -r $req_file

		これにより:
		• requirements.txt内のすべての依存関係をpyproject.tomlに追加
		• uv.lockファイルを自動生成/更新
		• 仮想環境を自動的に同期

		💡 制約ファイルがある場合:
		uv add -r $req_file -c constraints.txt

		📌 注意: この方法が最も確実で、バージョン指定も正しく処理されます"
		}
		EOF
        exit 0
    fi

    # 開発依存関係
    if [[ "$pip_cmd" =~ --dev ]] || [[ "$pip_cmd" =~ -e ]]; then
        cat <<- EOF
		{
		  "decision": "block",
		  "reason": "🔧 開発依存関係をインストール:

		uv add --dev $packages

		編集可能インストール: uv add -e ."
		}
		EOF
        exit 0
    fi

    # 通常のインストール
    cat <<- EOF
	{
	  "decision": "block",
	  "reason": "📦 パッケージをインストール:

	uv add $packages

	💾 'uv add' はpyproject.tomlに依存関係を保存します
	🔒 uv.lockで再現可能な環境を保証

	💡 特殊なケース:
	• URLからのインストール: パッケージを手動でダウンロードしてから追加
	• 開発版: uv add --dev $packages
	• ローカルパッケージ: uv add -e ./path/to/package"
	}
	EOF
    exit 0
}

# pip uninstallコマンドの処理
function handle_pip_uninstall() {
    local pip_cmd="$1"
    local packages=$(echo "$pip_cmd" | sed 's/uninstall//' | sed 's/-y//g' | xargs)
    cat <<- EOF
	{
	  "decision": "block",
	  "reason": "🗑️ パッケージを削除:

	uv remove $packages

	✨ 依存関係も自動的にクリーンアップされます"
	}
	EOF
    exit 0
}

# pip list/freezeコマンドの処理
function handle_pip_list() {
    cat <<- 'EOF'
	{
	  "decision": "block",
	  "reason": "📊 パッケージ一覧を確認:

	• プロジェクト依存関係: cat pyproject.toml
	• ロックファイル詳細: cat uv.lock
	• インストール済み一覧: uv tree
	• requirements.txt形式でエクスポート: uv export --format requirements-txt

	💡 'uv tree'はプロジェクトの依存関係ツリーを表示します"
	}
	EOF
    exit 0
}

# その他のpipコマンドの処理
function handle_pip_other() {
    local pip_cmd="$1"
    cat <<- EOF
	{
	  "decision": "block",
	  "reason": "🔀 pipコマンドをuvで実行:

	uv $pip_cmd

	💡 パッケージのインストール/削除には 'uv add/remove' を使用してください"
	}
	EOF
    exit 0
}

# python -m pipコマンドの処理
function handle_python_m_pip() {
    local pip_cmd="$1"

    # Parse pip install commands
    if [[ "$pip_cmd" =~ ^install ]]; then
        local packages=$(echo "$pip_cmd" | sed 's/install//' | sed 's/--[^ ]*//g' | xargs)
        if [[ "$pip_cmd" =~ -r\ .*\.txt ]]; then
            local req_file=$(echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
            cat <<- EOF
			{
			  "decision": "block",
			  "reason": "📋 requirements.txtからインストール:

			✅ 推奨方法:
			uv add -r $req_file

			💡 これによりすべての依存関係がpyproject.tomlに追加されます"
			}
			EOF
        else
            cat <<- EOF
			{
			  "decision": "block",
			  "reason": "📦 パッケージをインストール:

			uv add $packages

			💡 'uv add' はpyproject.tomlに依存関係を保存します"
			}
			EOF
        fi
    else
        cat <<- EOF
		{
		  "decision": "block",
		  "reason": "🔀 pipコマンドをuvで実行:

		uv $pip_cmd

		💡 パッケージ管理には 'uv add/remove' を使用してください"
		}
		EOF
    fi
    exit 0
}

# python -m moduleコマンドの処理
function handle_python_m_module() {
    local module="$1"
    cat <<- EOF
	{
	  "decision": "block",
	  "reason": "uvでモジュールを実行:

	uv run python -m $module

	🔄 uvは自動的に環境を同期してから実行します。"
	}
	EOF
    exit 0
}

# 基本的なPython実行の処理
function handle_python_run() {
    local args="$1"
    cat <<- EOF
	{
	  "decision": "block",
	  "reason": "uvでPythonを実行:

	uv run $args

	✅ 仮想環境のアクティベーションは不要です！"
	}
	EOF
    exit 0
}

# ===== メイン処理 =====
function main() {
    local input=$(cat)

    # Validate input
    if [ -z "$input" ]; then
        echo '{"decision": "approve"}'
        exit 0
    fi

    # Extract fields with error handling
    local tool_name=$(echo "$input" | jq -r '.tool_name' 2> /dev/null || echo "")
    local command=$(echo "$input" | jq -r '.tool_input.command // ""' 2> /dev/null || echo "")
    local file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2> /dev/null || echo "")
    local current_dir=$(pwd)

    # ===== pip関連コマンド =====
    if [[ "$tool_name" == "Bash" ]]; then
        case "$command" in
        pip\ * | pip3\ *)
            # pipコマンドの詳細な解析
            local pip_cmd=$(echo "$command" | sed -E 's/^pip[0-9]? *//' | xargs)

            case "$pip_cmd" in
            install\ *)
                handle_pip_install "$pip_cmd"
                ;;
            uninstall\ *)
                handle_pip_uninstall "$pip_cmd"
                ;;
            list* | freeze*)
                handle_pip_list
                ;;
            *)
                handle_pip_other "$pip_cmd"
                ;;
            esac
            ;;

        # ===== 直接的なPython実行の処理 =====
        python* | python3* | py\ *)
            # 通常のuvへの変換
            local args=$(echo "$command" | sed -E 's/^python[0-9]? //' | xargs)

            # -m オプションの特別処理
            if [[ "$args" =~ ^-m ]]; then
                local module=$(echo "$args" | sed 's/-m //')

                case "$module" in
                pip\ *)
                    local pip_cmd=$(echo "$module" | sed 's/pip //')
                    handle_python_m_pip "$pip_cmd"
                    ;;
                *)
                    handle_python_m_module "$module"
                    ;;
                esac
            fi

            # 基本的なPython実行
            handle_python_run "$args"
            ;;
        esac
    fi

    # デフォルトは承認
    echo '{"decision": "approve"}'
}

# スクリプト実行
main
