import os
import re

WORKFLOWS_DIR = os.path.join('.github', 'workflows')
CONDITION = "if: github.event_name == 'pull_request'"

def update_workflow_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    in_github_script_step = False
    step_start = None
    uses_github_script = False
    has_if_condition = False
    create_comment_found = False

    for i, line in enumerate(lines):
        stripped = line.strip()
        # Detect start of a step
        if re.match(r'^- name:', stripped):
            # If previous step needs fixing, insert/replace if condition
            if in_github_script_step and uses_github_script and create_comment_found:
                if not has_if_condition:
                    # Insert the if condition after the step name
                    new_lines.insert(step_start + 1, '  ' * (lines[step_start].count('  ') + 1) + CONDITION + '\n')
                else:
                    # Replace existing if condition
                    for j in range(step_start + 1, i):
                        if lines[j].strip().startswith('if:'):
                            indent = '  ' * (lines[j].count('  '))
                            lines[j] = f"{indent}{CONDITION}\n"
                    new_lines = lines[:i]
            # Reset flags for new step
            in_github_script_step = True
            step_start = i
            uses_github_script = False
            has_if_condition = False
            create_comment_found = False
        if in_github_script_step:
            if 'uses:' in stripped and 'actions/github-script' in stripped:
                uses_github_script = True
            if stripped.startswith('if:'):
                has_if_condition = True
            if 'github.rest.issues.createComment' in stripped:
                create_comment_found = True
        new_lines.append(line)

    # Handle last step in file
    if in_github_script_step and uses_github_script and create_comment_found:
        if not has_if_condition:
            new_lines.insert(step_start + 1, '  ' * (lines[step_start].count('  ') + 1) + CONDITION + '\n')
        else:
            for j in range(step_start + 1, len(lines)):
                if lines[j].strip().startswith('if:'):
                    indent = '  ' * (lines[j].count('  '))
                    lines[j] = f"{indent}{CONDITION}\n"
            new_lines = lines

    # Write back if changed
    if new_lines != lines:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Updated: {filepath}")

def main():
    for root, dirs, files in os.walk(WORKFLOWS_DIR):
        for file in files:
            if file.endswith('.yml') or file.endswith('.yaml'):
                update_workflow_file(os.path.join(root, file))

if __name__ == "__main__":
    main()