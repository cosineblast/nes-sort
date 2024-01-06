(ns gen.core
  (:import [java.io File FileOutputStream]))

(defn todo [] (throw (RuntimeException. "todo")))


(defn transpose [xs] (apply mapv vector xs))

(defn generate-tile [x y]
  (let [left-column (concat (repeat (* 2 (- 4 x)) 0)
                       (repeat (* 2 x) 1))
        right-column (concat (repeat (* 2 (- 4 y)) 0)
                       (repeat (* 2 y) 1))

        transposed (concat (repeat 4 left-column) (repeat 4 right-column))

        matrix (transpose transposed)]

    (flatten matrix)))

(defn row->byte [row]
  (first
   (reduce (fn [[result power] x] [(+ result (* x power)) (* 2 power)])
           [0 1]
           (reverse row))))

(defn tile->word [tile]
  (let [tile (map long tile)
        left-bit #(bit-shift-right (bit-and % 0x2) 1)
        right-bit #(bit-and % 0x1)
        [left-bytes right-bytes]
        (for [pick-bit [left-bit right-bit]]
          (->> tile
               (map pick-bit)
               (partition 8)
               (map row->byte)))]
    (concat right-bytes left-bytes)))

(defn -main []
  (let  [all-tiles (for [i (range 5) j (range 5)] (generate-tile i j))
         pattern-table (map tile->word all-tiles)]
    (with-open [file (->> "pattern-table.bin" File. FileOutputStream.)]
      (doseq [byte (flatten pattern-table)]
        (.write file (int byte))))))

(-main)
