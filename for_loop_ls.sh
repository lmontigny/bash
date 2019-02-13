for f in `ls *.gz`
do
  tar -xzf $f --strip-components 1   # strips subdirectory structure
done
