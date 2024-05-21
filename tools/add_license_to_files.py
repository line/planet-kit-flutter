import os
import sys

def add_license_to_files(directory, license_text, file_extensions):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(tuple(file_extensions)):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()

                if license_text not in content:
                    content = license_text + '\n\n' + content
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"License added to {file_path}")
                else:
                    print(f"License already present in {file_path}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python add_license_to_files.py <directory>")
        sys.exit(1)

    directory = sys.argv[1]

    license_text = """// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License."""

    file_extensions = ['.dart', '.swift', '.kt']

    add_license_to_files(directory, license_text, file_extensions)

if __name__ == "__main__":
    main()