" The MIT License (MIT)
"
" Copyright (c) 2017 Junegunn Choi
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

let s:lib = shellescape(expand('<sfile>:h:h').'/lib')
let s:bin = shellescape(expand('<sfile>:h:h').'/exe/heytmux')

function! s:heytmux(args, focus, count, line1, line2)
  if !executable('ruby')
    throw 'ruby executable not found'
  endif

  let files = filter(copy(a:args), 'v:val[0] != "-"')
  let opts = join(filter(copy(a:args), 'v:val[0] == "-"'))

  if a:count < 0
    let args = empty(files)
          \ ? shellescape(expand('%'))
          \ : join(map(copy(files), 'shellescape(v:val)'))
  else
    let args = tempname()
    call writefile(getline(a:line1, a:line2), args)
  endif
  let command = printf('ruby -I%s %s %s %s < /dev/tty',
        \ s:lib, s:bin, (a:focus ? '' : '-d ').opts, args)
  let out = system(command)
  if v:shell_error
    echo substitute(out, "\n$", '', '')
  endif
endfunction

command! -range=% -nargs=* -bang -complete=file
    \ Heytmux call s:heytmux([<f-args>], <bang>1, <count>, <line1>, <line2>)
