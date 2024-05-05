package toupper

import (
"strings"
)

#Transform: {
  input: #Input
  output: #Output

  _computed: strings.ToUpper(input.value)

  output: {
    value: _computed
  }
}
